//
//  VideoSerieController.swift
//  App
//
//  Created by Christoph Pageler on 24.10.18.
//


import Vapor
import FluentMySQL


final class VideoSerieController {

    func index(_ req: Request) throws -> Future<[VideoSerie]> {
        return VideoSerie
            .query(on: req)
            .filter(\.isDraft == false)
            .all()
    }

    func indexDraft(_ req: Request) throws -> Future<[VideoSerie]> {
        return VideoSerie
            .query(on: req)
            .filter(\.isDraft == true)
            .all()
    }

    func show(_ req: Request) throws -> Future<VideoSerie> {
        return try req.parameters.next(VideoSerie.self)
    }

    func create(_ req: Request) throws -> Future<VideoSerie> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(VideoSerieEdit.self).flatMap { videoSerieEdit in
            let videoSerie = VideoSerie(title: videoSerieEdit.title,
                                        description: videoSerieEdit.description,
                                        isPublic: videoSerieEdit.isPublic,
                                        isDraft: !user.isAdmin)
            return videoSerie.save(on: req)
        }
    }

    func patch(_ req: Request) throws -> Future<VideoSerie> {
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            return try req.content.decode(VideoSerieEdit.self).flatMap { patchVideoSerie in
                videoSerie.title = patchVideoSerie.title
                videoSerie.description = patchVideoSerie.description
                videoSerie.isPublic = patchVideoSerie.isPublic
                videoSerie.updatedAt = Date()
                return videoSerie.save(on: req)
            }
        }
    }

    func publish(_ req: Request) throws -> Future<VideoSerie> {
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            videoSerie.isDraft = false
            videoSerie.updatedAt = Date()
            return videoSerie.save(on: req)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            return videoSerie.delete(on: req)
        }.transform(to: .ok)
    }

    func videos(_ req: Request) throws -> Future<[VideoSerieVideoRelation]> {
        return try req.parameters.next(VideoSerie.self).flatMap(to: [VideoSerieVideoRelation].self) { videoSerie in
            guard let videoSerieID = videoSerie.id else {
                throw Abort(.notFound)
            }

            let orderBy = MySQLOrderBy.orderBy(MySQLExpression.column(MySQLColumnIdentifier.column("YoutubeVideo",
                                                                                                   "publishedAt")),
                                               MySQLDirection.descending)
            return VideoSerieYoutubeVideo
                .query(on: req)
                .filter(\.videoSerieID, .equal, videoSerieID)
                .filter(\VideoSerieYoutubeVideo.isDraft == false)
                .join(\YoutubeVideo.id, to: \VideoSerieYoutubeVideo.youtubeVideoID)
                .alsoDecode(YoutubeVideo.self)
                .sort(orderBy)
                .all()
                .map
            { items in
                return items.map({ (arg0) -> VideoSerieVideoRelation in
                    let (videoSerieYoutubeVideo, youtubeVideo) = arg0
                    return VideoSerieVideoRelation(description: videoSerieYoutubeVideo.description,
                                                   video: youtubeVideo)
                })
            }
        }
    }

    func videosDraft(_ req: Request) throws -> Future<[VideoSerieVideoRelation]> {
        return try req.parameters.next(VideoSerie.self).flatMap(to: [VideoSerieVideoRelation].self) { videoSerie in
            guard let videoSerieID = videoSerie.id else {
                throw Abort(.notFound)
            }

            let orderBy = MySQLOrderBy.orderBy(MySQLExpression.column(MySQLColumnIdentifier.column("YoutubeVideo",
                                                                                                   "publishedAt")),
                                               MySQLDirection.descending)
            return VideoSerieYoutubeVideo
                .query(on: req)
                .filter(\.videoSerieID, .equal, videoSerieID)
                .filter(\VideoSerieYoutubeVideo.isDraft == true)
                .join(\YoutubeVideo.id, to: \VideoSerieYoutubeVideo.youtubeVideoID)
                .alsoDecode(YoutubeVideo.self)
                .sort(orderBy)
                .all()
                .map
            { items in
                return items.map({ (arg0) -> VideoSerieVideoRelation in
                    let (videoSerieYoutubeVideo, youtubeVideo) = arg0
                    return VideoSerieVideoRelation(description: videoSerieYoutubeVideo.description,
                                                   video: youtubeVideo)
                })
            }
        }
    }

    func addVideoRelation(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            return try req.parameters.next(YoutubeVideo.self).flatMap { youtubeVideo in
                guard let youtubeVideoID = youtubeVideo.id,
                    let videoSerieID = videoSerie.id
                else {
                    throw Abort(.notFound)
                }
                let newVideoSerieYoutubeVideo = VideoSerieYoutubeVideo(id: nil,
                                                                       youtubeVideoID: youtubeVideoID,
                                                                       videoSerieID: videoSerieID,
                                                                       isDraft: !user.isAdmin)
                return newVideoSerieYoutubeVideo
                    .save(on: req)
                    .transform(to: .ok)
            }
        }
    }

    func removeVideoRelation(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            return try req.parameters.next(YoutubeVideo.self).flatMap { youtubeVideo in
                guard let youtubeVideoID = youtubeVideo.id,
                    let videoSerieID = videoSerie.id
                else {
                    throw Abort(.notFound)
                }

                return VideoSerieYoutubeVideo
                    .query(on: req)
                    .filter(\.youtubeVideoID, .equal, youtubeVideoID)
                    .filter(\.videoSerieID, .equal, videoSerieID)
                    .delete()
                    .transform(to: .ok)
            }
        }
    }

    func videosRelations(_ req: Request) throws -> Future<[VideoSerieYoutubeVideoContent]> {
        return VideoSerieYoutubeVideo
            .query(on: req)
            .filter(\.isDraft == false)
            .all()
            .flatMap(to: [VideoSerieYoutubeVideoContent].self) { videoSerieYoutubeVideos in
            let mappedValues = videoSerieYoutubeVideos.map { videoSerieYoutubeVideo in
                return VideoSerieYoutubeVideoContent(id: videoSerieYoutubeVideo.id,
                                                     youtubeVideoID: videoSerieYoutubeVideo.youtubeVideoID,
                                                     videoSerieID: videoSerieYoutubeVideo.videoSerieID,
                                                     description: videoSerieYoutubeVideo.description,
                                                     createdAt: videoSerieYoutubeVideo.createdAt,
                                                     updatedAt: videoSerieYoutubeVideo.updatedAt)
            }
            return req.eventLoop.newSucceededFuture(result: mappedValues)
        }
    }

    func patchVideoRelation(_ req: Request) throws -> Future<VideoSerieYoutubeVideoContent> {
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            return try req.parameters.next(YoutubeVideo.self).flatMap { youtubeVideo in
                guard let youtubeVideoID = youtubeVideo.id,
                    let videoSerieID = videoSerie.id
                else {
                    throw Abort(.notFound)
                }

                return VideoSerieYoutubeVideo
                    .query(on: req)
                    .filter(\.youtubeVideoID, .equal, youtubeVideoID)
                    .filter(\.videoSerieID, .equal, videoSerieID)
                    .first()
                    .flatMap
                { videoSerieYoutubeVideo in
                    guard let videoSerieYoutubeVideo = videoSerieYoutubeVideo else {
                        throw Abort(.notFound)
                    }

                    return try req.content.decode(VideoSerieYoutubeVideoUpdateRequest.self).flatMap { patchVideoSerie in
                        videoSerieYoutubeVideo.description = patchVideoSerie.description
                        return videoSerieYoutubeVideo.save(on: req).map { videoSerieYoutubeVideo in
                            return VideoSerieYoutubeVideoContent(id: videoSerieYoutubeVideo.id,
                                                                 youtubeVideoID: videoSerieYoutubeVideo.youtubeVideoID,
                                                                 videoSerieID: videoSerieYoutubeVideo.videoSerieID,
                                                                 description: videoSerieYoutubeVideo.description,
                                                                 createdAt: videoSerieYoutubeVideo.createdAt,
                                                                 updatedAt: videoSerieYoutubeVideo.updatedAt)
                        }
                    }
                }
            }
        }
    }

    func publishVideoRelation(_ req: Request) throws -> Future<VideoSerieYoutubeVideoContent> {
        return try req.parameters.next(VideoSerie.self).flatMap { videoSerie in
            return try req.parameters.next(YoutubeVideo.self).flatMap { youtubeVideo in
                guard let youtubeVideoID = youtubeVideo.id,
                    let videoSerieID = videoSerie.id
                else {
                    throw Abort(.notFound)
                }

                return VideoSerieYoutubeVideo
                    .query(on: req)
                    .filter(\.youtubeVideoID, .equal, youtubeVideoID)
                    .filter(\.videoSerieID, .equal, videoSerieID)
                    .first()
                    .flatMap
                { videoSerieYoutubeVideo in
                    guard let videoSerieYoutubeVideo = videoSerieYoutubeVideo else {
                        throw Abort(.notFound)
                    }

                    videoSerieYoutubeVideo.isDraft = false
                    videoSerieYoutubeVideo.updatedAt = Date()
                    
                    return videoSerieYoutubeVideo.save(on: req).map { videoSerieYoutubeVideo in
                        return VideoSerieYoutubeVideoContent(id: videoSerieYoutubeVideo.id,
                                                             youtubeVideoID: videoSerieYoutubeVideo.youtubeVideoID,
                                                             videoSerieID: videoSerieYoutubeVideo.videoSerieID,
                                                             description: videoSerieYoutubeVideo.description,
                                                             createdAt: videoSerieYoutubeVideo.createdAt,
                                                             updatedAt: videoSerieYoutubeVideo.updatedAt)
                    }
                }
            }
        }
    }

}
