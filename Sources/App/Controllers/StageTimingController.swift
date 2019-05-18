//
//  StageTimingController.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Vapor


final class StageTimingController {

    func index(_ req: Request) throws -> Future<[StageTiming]> {
        return StageTiming.query(on: req).all()
    }

    func show(_ req: Request) throws -> Future<StageTiming> {
        return try req.parameters.next(StageTiming.self)
    }

    func create(_ req: Request) throws -> Future<StageTiming> {
        return try req.content.decode(StageTiming.self).flatMap { stageTiming in
            return stageTiming.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                return stageTiming.save(on: req)
            }
        }
    }

    func patch(_ req: Request) throws -> Future<StageTiming> {
        return try req.parameters.next(StageTiming.self).flatMap { stageTiming in
            return try req.content.decode(StageTiming.self).flatMap { patchStageTiming in
                stageTiming.range = patchStageTiming.range
                stageTiming.second1 = patchStageTiming.second1
                stageTiming.second2 = patchStageTiming.second2
                stageTiming.second3 = patchStageTiming.second3
                stageTiming.stageID = patchStageTiming.stageID
                stageTiming.updatedAt = Date()

                return stageTiming.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                    return stageTiming.save(on: req)
                }
            }
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(StageTiming.self).flatMap { stageTiming in
            return stageTiming.delete(on: req)
        }.transform(to: .ok)
    }

}
