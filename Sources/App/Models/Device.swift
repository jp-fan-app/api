//
//  Device.swift
//  App
//
//  Created by Christoph Pageler on 14.08.18.
//


import FluentMySQL
import Vapor
import SwiftyJSON


final class Device: MySQLModel {

    enum Platform: Int, Codable {

        case ios
        case android

        func oneSignalCode() -> Int {
            switch self {
            case .ios: return 0
            case .android: return 1
            }
        }

    }

    var id: Int?
    var platform: Platform
    var pushToken: String
    var languageCode: String
    var externalID: String?
    var isTestDevice: Bool?
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         platform: Platform,
         pushToken: String,
         countryCode: String,
         externalID: String?,
         isTestDevice: Bool?) {
        self.id = id
        self.platform = platform
        self.pushToken = pushToken
        self.languageCode = countryCode
        self.externalID = externalID
        self.isTestDevice = isTestDevice
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var notificationPreferences: Children<Device, NotificationPreference> {
        return children(\.deviceID)
    }

    func updateOneSignal(db: DatabaseConnectable, eventLoop: EventLoop) -> EventLoopFuture<Device> {
        return HTTPClient.connect(scheme: .https,
                                  hostname: "onesignal.com",
                                  on: eventLoop,
                                  onError: { _ in })
        .flatMap(to: HTTPResponse.self) { httpClient in
            let bodyDict: [String: Any] = [
                "app_id": OneSignal.appID(),
                "device_type": self.platform.oneSignalCode(),
                "identifier": self.pushToken,
                "language": self.languageCode,
                "test_type": ((self.isTestDevice ?? false) ? 1 : nil) as Any
            ]
            let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict,
                                                       options: [])
            let body = HTTPBody(data: bodyData ?? Data())

            if let externalID = self.externalID {
                return httpClient.send(HTTPRequest(method: .PUT,
                                                   url: "/api/v1/players/\(externalID)",
                                                   version: HTTPVersion(major: 1, minor: 1),
                                                   headers: HTTPHeaders([
                                                    ("Content-Type", "application/json")
                                                   ]),
                                                   body: body))
            } else {
                return httpClient.send(HTTPRequest(method: .POST,
                                                   url: "/api/v1/players",
                                                   version: HTTPVersion(major: 1, minor: 1),
                                                   headers: HTTPHeaders([
                                                    ("Content-Type", "application/json")
                                                    ]),
                                                   body: body))
            }

        }.flatMap(to: Device.self) { response in
            guard let data = response.body.data else {
                return eventLoop.newSucceededFuture(result: self)
            }
            guard self.externalID == nil else {
                return eventLoop.newSucceededFuture(result: self)
            }

            let json = JSON(data: data)
            self.externalID = json["id"].string
            self.updatedAt = Date()
            
            return self.save(on: db)
        }
    }

    func removeFromOneSignal(eventLoop: EventLoop) -> EventLoopFuture<Device> {
        guard let externalID = externalID else {
            return eventLoop.newSucceededFuture(result: self)
        }
        return HTTPClient.connect(scheme: .https,
                                  hostname: "onesignal.com",
                                  on: eventLoop,
                                  onError: { _ in })
        .flatMap(to: HTTPResponse.self) { httpClient in
            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "app_id", value: OneSignal.appID()),
            ]

            let request = HTTPRequest(method: .DELETE,
                                      url: "/api/v1/players/\(externalID)?\(components.query ?? "")",
                                      version: HTTPVersion(major: 1, minor: 1),
                                      headers: HTTPHeaders([
                                        ("Authorization", "Basic \(OneSignal.restAPIKey())")
                                      ]),
                                      body: HTTPBody())

            return httpClient.send(request)
        }.map(to: Device.self) { response in
            return self
        }
    }

    func pingOneSignal(eventLoop: EventLoop) -> EventLoopFuture<Void> {
        guard let externalID = externalID else {
            return eventLoop.newSucceededFuture(result: ())
        }
        return HTTPClient.connect(scheme: .https,
                                  hostname: "onesignal.com",
                                  on: eventLoop,
                                  onError: { _ in })
        .flatMap(to: HTTPResponse.self) { httpClient in
            let bodyDict: [String: Any] = [
                "app_id": OneSignal.appID(),
                "identifier": self.pushToken,
                "language": self.languageCode,
                "device_type": self.platform.oneSignalCode(),
                "test_type": ((self.isTestDevice ?? false) ? 1 : nil) as Any
            ]
            let bodyData = try? JSONSerialization.data(withJSONObject: bodyDict,
                                                       options: [])
            let body = HTTPBody(data: bodyData ?? Data())

            let request = HTTPRequest(method: .POST,
                                      url: "/api/v1/players/\(externalID)/on_session",
                                      version: HTTPVersion(major: 1, minor: 1),
                                      headers: HTTPHeaders([
                                        ("Content-Type", "application/json")
                                      ]),
                                      body: body)

            return httpClient.send(request)
        }.map(to: Void.self) { response in
            return ()
        }
    }

}


extension Device: Migration { }


extension Device: Content { }


extension Device: Parameter { }
