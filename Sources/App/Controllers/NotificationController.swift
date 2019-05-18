//
//  NotificationController.swift
//  App
//
//  Created by Christoph Pageler on 14.08.18.
//


import Vapor


final class NotificationController {

    func devicesForEntityPair(_ req: Request) throws -> Future<[Device]> {
        let entityPair = try req.query.decode(EntityPair.self)
        return NotificationPreference.devicesMatchingWith(entityPair: entityPair, db: req)
    }

    func sendNotificationForEntityPair(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(EntityPair.self).flatMap(to: Void.self) { entityPair in
            let promise = req.eventLoop.newPromise(Void.self)
            try NotificationController.sendNotificationForEntityPair(entityPair: entityPair,
                                                                     db: req,
                                                                     eventLoop: req.eventLoop,
                                                                     promise: promise)
            return promise.futureResult
        }.transform(to: .ok)
    }

    func track(_ req: Request) throws -> Future<HTTPStatus> {
        let notificationID = try req.parameters.next(String.self)
        return HTTPClient.connect(scheme: .https,
                                  hostname: "onesignal.com",
                                  on: req,
                                  onError: { _ in })
        .flatMap(to: HTTPResponse.self) { httpClient in
            let bodyDict: [String: Any] = [
                "app_id": OneSignal.appID,
                "opened": true
            ]
            let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict,
                                                       options: [])
            let body = HTTPBody(data: bodyData ?? Data())
            let request = HTTPRequest(method: .PUT,
                                      url: "/api/v1/notifications/\(notificationID)",
                                      version: HTTPVersion(major: 1, minor: 1),
                                      headers: HTTPHeaders([
                                        ("Content-Type", "application/json")
                                      ]),
                                      body: body)
            return httpClient.send(request)
        }.transform(to: .ok)
    }

    static func sendNotificationForEntityPair(entityPair: EntityPair,
                                              db: DatabaseConnectable,
                                              eventLoop: EventLoop,
                                              promise: Promise<Void>) throws {
        guard entityPair.entityID != nil else {
            promise.fail(error: Abort(.badRequest,
                                      headers: HTTPHeaders(),
                                      reason: "`entityID` must be set when sending notifications",
                                      identifier: nil))
            return
        }

        _ = NotificationPreference
            .devicesMatchingWith(entityPair: entityPair, db: db)
            .flatMap(to: NotificationBox.self)
        { devices -> EventLoopFuture<NotificationBox> in
            return eventLoop.newSucceededFuture(result: NotificationBox(devices: devices,
                                                                        entityPair: entityPair))
        }.flatMap(to: Void.self) { notificationBox in
            guard let entityIDString = notificationBox.entityPair.entityID, let entityIDInt = Int(entityIDString) else {
                promise.fail(error: Abort(.badRequest,
                                          headers: HTTPHeaders(),
                                          reason: "`entityID` must be an integer",
                                          identifier: nil))
                return promise.futureResult
            }

            switch notificationBox.entityPair.entityType {
            case "Video":
                try self.sendVideoNotifications(videoID: entityIDInt,
                                                notificationBox: notificationBox,
                                                db: db,
                                                eventLoop: eventLoop,
                                                promise: promise)
            case "CarModel":
                try self.sendCarModelNotifications(carModelID: entityIDInt,
                                                   notificationBox: notificationBox,
                                                   db: db,
                                                   eventLoop: eventLoop,
                                                   promise: promise)
            default:
                promise.fail(error: Abort(.badRequest,
                                          headers: HTTPHeaders(),
                                          reason: "Entity Type `\(notificationBox.entityPair.entityType)` not allowed",
                                          identifier: nil))
            }
            return promise.futureResult
        }
    }

    private static func sendVideoNotifications(videoID: Int,
                                               notificationBox: NotificationBox,
                                               db: DatabaseConnectable,
                                               eventLoop: EventLoop,
                                               promise: Promise<Void>) throws {
        _ = YoutubeVideo.find(videoID, on: db).flatMap(to: Void.self) { youtubeVideo in
            guard let youtubeVideo = youtubeVideo else {
                promise.fail(error: Abort(.notFound))
                return promise.futureResult
            }
            try sendNotifications(SendNotification(content: LocalizedValue(en: youtubeVideo.title,
                                                                                de: youtubeVideo.title),
                                                   heading: LocalizedValue(en: "New Video",
                                                                           de: "Neues Video")),
                                  notificationBox: notificationBox,
                                  androidChannelID:  "f97b19c7-b87c-491a-a3c3-f154a08e4628",
                                  eventLoop: eventLoop,
                                  promise: promise)
            return promise.futureResult
        }
    }

    private static func sendCarModelNotifications(carModelID: Int,
                                                  notificationBox: NotificationBox,
                                                  db: DatabaseConnectable,
                                                  eventLoop: EventLoop,
                                                  promise: Promise<Void>) throws {
        _ = CarModel.find(carModelID, on: db).flatMap(to: Void.self) { carModel in
            guard let carModel = carModel else {
                promise.fail(error: Abort(.notFound))
                return promise.futureResult
            }
            return carModel.manufacturer.get(on: db).flatMap { manufacturer in
                let content = "\(manufacturer.name) \(carModel.name)"
                try sendNotifications(SendNotification(content: LocalizedValue(en: content,
                                                                               de: content),
                                                       heading: LocalizedValue(en: "Car Update",
                                                                               de: "Auto Update")),
                                      notificationBox: notificationBox,
                                      androidChannelID: "ba663876-56ba-43dd-b666-1432855a08ff",
                                      eventLoop: eventLoop,
                                      promise: promise)
                return promise.futureResult
            }
        }
    }

    private static func sendNotifications(_ notification: SendNotification,
                                          notificationBox: NotificationBox,
                                          androidChannelID: String,
                                          eventLoop: EventLoop,
                                          promise: Promise<Void>) throws {
        let queue = DispatchQueue(label: "sendVideoNotifications",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        queue.async {
            let dispatchGroup = DispatchGroup()

            let chunkSize = 2000
            for deviceChunk in notificationBox.devices.chunks(chunkSize) {

                dispatchGroup.wait()
                dispatchGroup.enter()

                _ = try? HTTPClient.connect(scheme: .https,
                                            hostname: "onesignal.com",
                                            on: eventLoop,
                                            onError: { _ in })
                .flatMap(to: HTTPResponse.self) { httpClient in
                    let bodyDict: [String: Any] = [
                        "app_id": OneSignal.appID,
                        "include_player_ids": deviceChunk.compactMap({ $0.externalID }),
                        "headings": [
                            "en": notification.heading.en,
                            "de": notification.heading.de
                        ],
                        "contents": [
                            "en": notification.content.en,
                            "de": notification.content.de,
                        ],
                        "data": [
                            "entityType": notificationBox.entityPair.entityType,
                            "entityID": notificationBox.entityPair.entityID
                        ],
                        "android_channel_id": androidChannelID
                    ]
                    let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict,
                                                               options: [])
                    let body = HTTPBody(data: bodyData ?? Data())
                    let request = HTTPRequest(method: .POST,
                                              url: "/api/v1/notifications",
                                              version: HTTPVersion(major: 1, minor: 1),
                                              headers: HTTPHeaders([
                                                ("Content-Type", "application/json"),
                                                ("Authorization", "Basic 44da9574-7387-4c29-be87-46b18b40bcd9:")
                                              ]),
                                              body: body)
                    print("send notifications for `\(notification.content.en)` to \(deviceChunk.compactMap({ $0.externalID }).count) devices")
                    return httpClient.send(request)
                }.map(to: Void.self) { response in
                    print("send notification response: \(String(data: response.body.data ?? Data(), encoding: .utf8) ?? "")")
                    dispatchGroup.leave()
                    return ()
                }.wait()
            }

            dispatchGroup.wait()
            promise.succeed()
        }
    }

}


private struct NotificationBox {

    let devices: [Device]
    let entityPair: EntityPair

}

private struct SendNotification {

    let content: LocalizedValue
    let heading: LocalizedValue

}

private struct LocalizedValue {

    let en: String
    let de: String

}
