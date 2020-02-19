//
//  CarModel.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import FluentMySQL
import Vapor


final class CarModel: MySQLModel {

    enum TransmissionType: Int, Codable {

        case manual
        case automatic

    }

    enum AxleType: Int, Codable {

        case all
        case front
        case rear

    }

    var id: Int?
    var name: String
    var manufacturerID: Manufacturer.ID
    var transmissionType: TransmissionType
    var axleType: AxleType
    var mainImageID: CarImage.ID?
    var isDraft: Bool
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         name: String,
         manufacturerID: Manufacturer.ID,
         transmissionType: TransmissionType,
         axleType: AxleType,
         mainImageID: CarImage.ID?,
         isDraft: Bool) {
        self.id = id
        self.name = name
        self.manufacturerID = manufacturerID
        self.transmissionType = transmissionType
        self.axleType = axleType
        self.mainImageID = mainImageID
        self.isDraft = isDraft
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var manufacturer: Parent<CarModel, Manufacturer> {
        return parent(\.manufacturerID)
    }

    var images: Children<CarModel, CarImage> {
        return children(\.carModelID)
    }

    var stages: Children<CarModel, CarStage> {
        return children(\.carModelID)
    }

    func ensureRelations(eventLoop: EventLoop, on db: DatabaseConnectable) -> EventLoopFuture<Void> {
        return Manufacturer.find(manufacturerID, on: db).flatMap { manufacturer in
            guard manufacturer != nil else {
                throw Abort(.notFound, headers: HTTPHeaders(), reason: "manufacturerID not found")
            }

            if let mainImageID = self.mainImageID {
                return CarImage.find(mainImageID, on: db).flatMap { mainImage in
                    guard mainImage != nil else {
                        throw Abort(.notFound, headers: HTTPHeaders(), reason: "mainImageID not found")
                    }
                    return eventLoop.newSucceededFuture(result: ())
                }
            } else {
                return eventLoop.newSucceededFuture(result: ())
            }
        }
    }

}


extension CarModel: Migration { }


extension CarModel: Content { }


extension CarModel: Parameter { }


struct CarModelEdit: Content {

    var name: String
    var manufacturerID: Manufacturer.ID
    var transmissionType: CarModel.TransmissionType
    var axleType: CarModel.AxleType
    var mainImageID: CarImage.ID?

}
