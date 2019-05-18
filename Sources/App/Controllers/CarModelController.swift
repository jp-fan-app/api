//
//  CarModelController.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor


final class CarModelController {

    func index(_ req: Request) throws -> Future<[CarModel]> {
        return CarModel.query(on: req).all()
    }

    func show(_ req: Request) throws -> Future<CarModel> {
        return try req.parameters.next(CarModel.self)
    }

    func create(_ req: Request) throws -> Future<CarModel> {
        return try req.content.decode(CarModel.self).flatMap { carModel in
            return carModel.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                return carModel.save(on: req)
            }
        }
    }

    func patch(_ req: Request) throws -> Future<CarModel> {
        return try req.parameters.next(CarModel.self).flatMap { carModel in
            return try req.content.decode(CarModel.self).flatMap { patchCarModel in
                carModel.name = patchCarModel.name
                carModel.manufacturerID = patchCarModel.manufacturerID
                carModel.transmissionType = patchCarModel.transmissionType
                carModel.axleType = patchCarModel.axleType
                carModel.mainImageID = patchCarModel.mainImageID
                carModel.updatedAt = Date()

                return carModel.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                    return carModel.save(on: req)
                }
            }
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarModel.self).flatMap { carModel in
            return carModel.delete(on: req)
        }.transform(to: .ok)
    }

    func images(_ req: Request) throws -> Future<[ResolvedCarImage]> {
        return try req.parameters.next(CarModel.self).flatMap(to: [CarImage].self) { carModel in
            return try carModel.images.query(on: req).all()
        }.map(to: [ResolvedCarImage].self) { carImages in
            return carImages.compactMap({ $0.resolvedCarImage() })
        }
    }

    func stages(_ req: Request) throws -> Future<[CarStage]> {
        return try req.parameters.next(CarModel.self).flatMap(to: [CarStage].self) { carModel in
            return try carModel.stages.query(on: req).all()
        }
    }

}
