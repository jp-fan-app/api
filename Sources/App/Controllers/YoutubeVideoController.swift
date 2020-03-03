//
//  YoutubeVideoController.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Vapor
import FluentMySQL


final class YoutubeVideoController {

    func videosQuery(_ req: Request) -> QueryBuilder<MySQLDatabase, YoutubeVideo> {
        return YoutubeVideo.query(on: req).sort(\.publishedAt, .descending)
    }

    func index(_ req: Request) throws -> Future<[YoutubeVideo]> {
        return videosQuery(req).all()
    }

    func show(_ req: Request) throws -> Future<YoutubeVideo> {
        return try req.parameters.next(YoutubeVideo.self)
    }

    func byVideoID(_ req: Request) throws -> Future<[YoutubeVideo]> {
        let searchVideoID = try req.parameters.next(String.self)
        return videosQuery(req)
            .filter(\.videoID, .equal, searchVideoID)
            .all()
    }

    // MARK: - Search

    struct SearchRequest: Codable {

        let publishedAtNewer: Date?
        let query: String?

    }

    func search(_ req: Request) throws -> Future<[YoutubeVideo]> {
        return try req.content.decode(SearchRequest.self).flatMap { search in
            let queryBuilder = self.videosQuery(req)

            if let publishedAtNewer = search.publishedAtNewer {
                queryBuilder.filter(\.publishedAt >= publishedAtNewer)
            }

            if let query = search.query {
                queryBuilder.group(.or, closure: { queryBuilder in
                    queryBuilder.filter(\.title, .like, "%\(query)%")
                    queryBuilder.filter(\.description, .like, "%\(query)%")
                    queryBuilder.filter(\.videoID, .like, "%\(query)%")
                })
            }

            return queryBuilder.all()
        }
    }

    // MARK: - Stages

    func stages(_ req: Request) throws -> Future<[CarStage]> {
        return try req.parameters.next(YoutubeVideo.self).flatMap(to: [CarStage].self) { youtubeVideo in
            return try youtubeVideo.stages.query(on: req).all()
        }
    }

    func series(_ req: Request) throws -> Future<[VideoSerie]> {
        return try req.parameters.next(YoutubeVideo.self).flatMap(to: [VideoSerie].self) { youtubeVideo in
            return try youtubeVideo.videoSeries
                .query(on: req)
                .filter(\.isDraft == false)
                .all()
        }
    }

}
