//
//  CarStageController.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Vapor


final class CarStageController {

    func index(_ req: Request) throws -> Future<[CarStage]> {
        return CarStage.query(on: req).all()
    }

    func show(_ req: Request) throws -> Future<CarStage> {
        return try req.parameters.next(CarStage.self)
    }

    func create(_ req: Request) throws -> Future<CarStage> {
        return try req.content.decode(CarStage.self).flatMap { carStage in
            return carStage.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                return carStage.save(on: req)
            }
        }
    }

    func patch(_ req: Request) throws -> Future<CarStage> {
        return try req.parameters.next(CarStage.self).flatMap { carStage in
            return try req.content.decode(CarStage.self).flatMap { patchCarStage in
                carStage.name = patchCarStage.name
                carStage.description = patchCarStage.description
                carStage.isStock = patchCarStage.isStock
                carStage.ps = patchCarStage.ps
                carStage.nm = patchCarStage.nm
                carStage.lasiseInSeconds = patchCarStage.lasiseInSeconds
                carStage.carModelID = patchCarStage.carModelID
                carStage.updatedAt = Date()

                return carStage.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                    return carStage.save(on: req)
                }
            }
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarStage.self).flatMap { carStage in
            return carStage.delete(on: req)
        }.transform(to: .ok)
    }

    func timings(_ req: Request) throws -> Future<[StageTiming]> {
        return try req.parameters.next(CarStage.self).flatMap(to: [StageTiming].self) { carStage in
            return try carStage.timings.query(on: req).all()
        }
    }

    func videos(_ req: Request) throws -> Future<[YoutubeVideo]> {
        return try req.parameters.next(CarStage.self).flatMap(to: [YoutubeVideo].self) { carStage in
            return try carStage.videos.query(on: req).all()
        }
    }

    func addVideoRelation(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarStage.self).flatMap { carStage in
            return try req.parameters.next(YoutubeVideo.self).flatMap { youtubeVideo in
                guard let youtubeVideoID = youtubeVideo.id,
                    let carStageID = carStage.id
                else {
                    throw Abort(.notFound)
                }
                let newCarStageYoutubeVideo = CarStageYoutubeVideo(id: nil,
                                                                   youtubeVideoID: youtubeVideoID,
                                                                   carStageID: carStageID)
                return newCarStageYoutubeVideo
                    .save(on: req)
                    .transform(to: .ok)
            }
        }
    }

    func removeVideoRelation(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarStage.self).flatMap { carStage in
            return try req.parameters.next(YoutubeVideo.self).flatMap { youtubeVideo in
                guard let youtubeVideoID = youtubeVideo.id,
                    let carStageID = carStage.id
                else {
                    throw Abort(.notFound)
                }

                return CarStageYoutubeVideo
                    .query(on: req)
                    .filter(\.youtubeVideoID, .equal, youtubeVideoID)
                    .filter(\.carStageID, .equal, carStageID)
                    .delete()
                    .transform(to: .ok)
            }
        }
    }

    func videosRelations(_ req: Request) throws -> Future<[CarStageYoutubeVideoContent]> {
        return CarStageYoutubeVideo.query(on: req).all().flatMap(to: [CarStageYoutubeVideoContent].self) { carStageYoutubeVideos in
            let mappedValues = carStageYoutubeVideos.map { carStageYoutubeVideo in
                return CarStageYoutubeVideoContent(id: carStageYoutubeVideo.id,
                                                   youtubeVideoID: carStageYoutubeVideo.youtubeVideoID,
                                                   carStageID: carStageYoutubeVideo.carStageID,
                                                   createdAt: carStageYoutubeVideo.createdAt,
                                                   updatedAt: carStageYoutubeVideo.updatedAt)
            }
            return req.eventLoop.newSucceededFuture(result: mappedValues)
        }
    }

}
