//
//  YoutubeVideoController.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Vapor
import FluentMySQL


final class YoutubeVideoController {

    func index(_ req: Request) throws -> Future<[YoutubeVideo]> {
        return YoutubeVideo.query(on: req).sort(\.publishedAt, .descending).all()
    }

    func show(_ req: Request) throws -> Future<YoutubeVideo> {
        return try req.parameters.next(YoutubeVideo.self)
    }

    func byVideoID(_ req: Request) throws -> Future<[YoutubeVideo]> {
        let searchVideoID = try req.parameters.next(String.self)
        return YoutubeVideo.query(on: req).filter(\.videoID, .equal, searchVideoID).all()
    }

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
