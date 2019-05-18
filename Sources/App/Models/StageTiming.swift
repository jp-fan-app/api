//
//  StageTiming.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import FluentMySQL
import Vapor


final class StageTiming: MySQLModel {

    var id: Int?
    var range: String
    var second1: Double?
    var second2: Double?
    var second3: Double?
    var stageID: CarStage.ID
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         range: String,
         second1: Double?,
         second2: Double?,
         second3: Double?,
         stageID: CarStage.ID) {
        self.id = id
        self.range = range
        self.second1 = second1
        self.second2 = second2
        self.second3 = second3
        self.stageID = stageID
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var stage: Parent<StageTiming, CarStage> {
        return parent(\.stageID)
    }

    func ensureRelations(eventLoop: EventLoop, on db: DatabaseConnectable) -> EventLoopFuture<Void> {
        return CarStage.find(stageID, on: db).flatMap { carStage in
            guard carStage != nil else {
                throw Abort(.notFound, headers: HTTPHeaders(), reason: "stageID not found")
            }

            return eventLoop.newSucceededFuture(result: ())
        }
    }

}


extension StageTiming: Migration { }


extension StageTiming: Content { }


extension StageTiming: Parameter { }
