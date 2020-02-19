//
//  CarStage.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import FluentMySQL
import Vapor


final class CarStage: MySQLModel {

    var id: Int?
    var name: String
    var description: String?
    var isStock: Bool
    var ps: Double?
    var nm: Double?
    var lasiseInSeconds: Double?
    var carModelID: CarModel.ID
    var isDraft: Bool
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         name: String,
         description: String?,
         isStock: Bool,
         ps: Double?,
         nm: Double?,
         lasiseInSeconds: Double?,
         carModelID: CarModel.ID,
         isDraft: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.isStock = isStock
        self.ps = ps
        self.nm = nm
        self.lasiseInSeconds = lasiseInSeconds
        self.carModelID = carModelID
        self.isDraft = isDraft
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var carModel: Parent<CarStage, CarModel> {
        return parent(\.carModelID)
    }

    var timings: Children<CarStage, StageTiming> {
        return children(\.stageID)
    }

    var videos: Siblings<CarStage, YoutubeVideo, CarStageYoutubeVideo> {
        return siblings()
    }

    func ensureRelations(eventLoop: EventLoop, on db: DatabaseConnectable) -> EventLoopFuture<Void> {
        return CarModel.find(carModelID, on: db).flatMap { carModel in
            guard carModel != nil else {
                throw Abort(.notFound, headers: HTTPHeaders(), reason: "carModelID not found")
            }

            return eventLoop.newSucceededFuture(result: ())
        }
    }

}


extension CarStage: Migration { }


extension CarStage: Content { }


extension CarStage: Parameter { }


struct CarStageEdit: Content {

    var name: String
    var description: String?
    var isStock: Bool
    var ps: Double?
    var nm: Double?
    var lasiseInSeconds: Double?
    var carModelID: CarModel.ID

}
