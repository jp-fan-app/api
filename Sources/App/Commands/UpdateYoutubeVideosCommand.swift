//
//  UpdateYoutubeVideosCommand.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Vapor
import SwiftyJSON
import FluentMySQL


struct UpdateYoutubeVideosCommand: Command {

    private func youtubeKey() -> String {
        return ProcessInfo.processInfo.environment["YOUTUBE_KEY"] ?? ""
    }

    var arguments: [CommandArgument] {
        return []
    }

    var options: [CommandOption] {
        return [
            .value(name: "recursive",
                   short: "r",
                   default: "false",
                   help: [
                    "Recursive Update on all available pages"
            ])
        ]
    }

    var help: [String] {
        return [
            "Aint nobody need help"
        ]
    }

    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        let fetchNextPage = context.options["recursive"] == "true"

        return try performSearch(using: context,
                                 pageToken: nil,
                                 fetchNextPage: fetchNextPage)
    }

    private func performSearch(using context: CommandContext,
                               pageToken: String?,
                               fetchNextPage: Bool) throws -> EventLoopFuture<Void> {
        return HTTPClient.connect(scheme: .https,
                                  hostname: "www.googleapis.com",
                                  on: context.container.eventLoop,
                                  onError: { _ in })
        .flatMap(to: HTTPResponse.self) { httpClient in
            var components = URLComponents()
            components.queryItems = [
                URLQueryItem(name: "part", value: "snippet"),
                URLQueryItem(name: "playlistId", value: "UU1-VOKyTJrgLiBeiJqzeIUQ"),
                URLQueryItem(name: "order", value: "date"),
                URLQueryItem(name: "maxResults", value: "50"),
                URLQueryItem(name: "key", value: self.youtubeKey()),
                URLQueryItem(name: "type", value: "video")
            ]
            if let pageToken = pageToken {
                components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken))
            }

            let request = HTTPRequest(method: .GET,
                                      url: "/youtube/v3/playlistItems?\(components.query ?? "")",
                version: HTTPVersion(major: 1, minor: 1),
                headers: HTTPHeaders(),
                body: HTTPBody())

            return httpClient.send(request)
        }.flatMap(to: YoutubeSearchResult?.self) { response in
            guard let data = response.body.data else {
                return context.container.eventLoop.future(nil)
            }
            let json = JSON(data: data)
            guard let result = YoutubeSearchResult(json: json) else {
                return context.container.eventLoop.future(nil)
            }
            return context.container.eventLoop.future(result)
        }.flatMap(to: YoutubeSearchResult.self) { youtubeSearchResult in
            return context.container.withPooledConnection(to: .mysql) { (db: MySQLDatabase.Connection) -> EventLoopFuture<()> in
                let promise = context.container.eventLoop.newPromise(Void.self)

                if let searchResult = youtubeSearchResult {
                    self.syncYoutubeSearchResult(searchResult,
                                                 in: db,
                                                 eventLoop: context.container.eventLoop,
                                                 promise: promise)
                }

                return promise.futureResult
            }.flatMap(to: YoutubeSearchResult.self) { _ in
                return context.container.eventLoop.future(youtubeSearchResult!)
            }
        }.flatMap(to: Void.self) { youtubeSearchResult in
            if fetchNextPage, let nextPageToken = youtubeSearchResult.nextPageToken {
                return try self.performSearch(using: context,
                                              pageToken: nextPageToken,
                                              fetchNextPage: true)
            } else {
                return context.container.eventLoop.future(())
            }
        }
    }

    private func syncYoutubeSearchResult(_ searchResult: YoutubeSearchResult,
                                         in db: MySQLDatabase.Connection,
                                         eventLoop: EventLoop,
                                         promise: EventLoopPromise<Void>) {
        let queue = DispatchQueue(label: "syncYoutubeSearchResult",
                                  qos: .default,
                                  attributes: .concurrent,
                                  autoreleaseFrequency: .inherit,
                                  target: nil)
        queue.async {
            for item in searchResult.items {
                if let youtubeVideoThrow = try? YoutubeVideo.query(on: db).filter(\.videoID == item.id).first().wait(),
                    let youtubeVideo = youtubeVideoThrow {
                    youtubeVideo.title = item.title
                    youtubeVideo.description = item.description
                    youtubeVideo.thumbnailURL = item.thumbnailURL
                    youtubeVideo.publishedAt = item.publishedAt
                    youtubeVideo.updatedAt = Date()

                    do {
                        _ = try youtubeVideo.save(on: db).wait()
                    } catch {
                        print("error: \(error)")
                    }
                } else {
                    let newVideo = YoutubeVideo(videoID: item.id,
                                                title: item.title,
                                                description: item.description,
                                                thumbnailURL: item.thumbnailURL,
                                                publishedAt: item.publishedAt)
                    _ = try? newVideo.save(on: db).flatMap { savedVideo -> EventLoopFuture<Void> in
                        guard let videoID = savedVideo.id else {
                            return eventLoop.newSucceededFuture(result: ())
                        }

                        let entityPair = EntityPair(entityType: "Video", entityID: "\(videoID)")

                        let sendPromise = eventLoop.newPromise(Void.self)
                        try NotificationController.sendNotificationForEntityPair(entityPair: entityPair,
                                                                                 db: db,
                                                                                 eventLoop: eventLoop,
                                                                                 promise: sendPromise)
                        return sendPromise.futureResult
                    }
                    .catch({ (error) in
                        print("error: \(error)")
                    })
                    .wait()
                }
            }
            promise.succeed()
        }
    }

}
