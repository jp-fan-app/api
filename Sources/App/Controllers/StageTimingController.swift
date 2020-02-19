//
//  StageTimingController.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Vapor
import FluentMySQL


final class StageTimingController {

    func index(_ req: Request) throws -> Future<[StageTiming]> {
        return StageTiming
            .query(on: req)
            .filter(\.isDraft == false)
            .all()
    }

    func indexDraft(_ req: Request) throws -> Future<[StageTiming]> {
        return StageTiming
            .query(on: req)
            .filter(\.isDraft == true)
            .all()
    }

    func show(_ req: Request) throws -> Future<StageTiming> {
        return try req.parameters.next(StageTiming.self)
    }

    func create(_ req: Request) throws -> Future<StageTiming> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(StageTimingEdit.self).flatMap { stageTimingEdit in
            let stageTiming = StageTiming(range: stageTimingEdit.range,
                                          second1: stageTimingEdit.second1,
                                          second2: stageTimingEdit.second2,
                                          second3: stageTimingEdit.second3,
                                          stageID: stageTimingEdit.stageID,
                                          isDraft: !user.isAdmin)
            return stageTiming.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                return stageTiming.save(on: req)
            }
        }
    }

    func patch(_ req: Request) throws -> Future<StageTiming> {
        return try req.parameters.next(StageTiming.self).flatMap { stageTiming in
            return try req.content.decode(StageTimingEdit.self).flatMap { patchStageTiming in
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

    func publish(_ req: Request) throws -> Future<StageTiming> {
        return try req.parameters.next(StageTiming.self).flatMap { stageTiming in
            stageTiming.isDraft = false
            stageTiming.updatedAt = Date()
            return stageTiming.save(on: req)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(StageTiming.self).flatMap { stageTiming in
            return stageTiming.delete(on: req)
        }.transform(to: .ok)
    }

}
