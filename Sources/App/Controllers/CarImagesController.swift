//
//  CarImagesController.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor
import FluentMySQL


final class CarImageController {

    func index(_ req: Request) throws -> Future<[ResolvedCarImage]> {
        return CarImage
            .query(on: req)
            .filter(\.isDraft == false)
            .all()
            .map(to: [ResolvedCarImage].self)
        { carImages in
            return carImages.compactMap({ $0.resolvedCarImage() })
        }
    }

    func indexDraft(_ req: Request) throws -> Future<[ResolvedCarImage]> {
        return CarImage
            .query(on: req)
            .filter(\.isDraft == true)
            .all()
            .map(to: [ResolvedCarImage].self)
        { carImages in
            return carImages.compactMap({ $0.resolvedCarImage() })
        }
    }

    func show(_ req: Request) throws -> Future<ResolvedCarImage> {
        return try req.parameters.next(CarImage.self).map(to: ResolvedCarImage.self, { $0.resolvedCarImage() })
    }

    func create(_ req: Request) throws -> Future<ResolvedCarImage> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CarImageEdit.self).flatMap { carImageEdit in
            let carImage = CarImage(copyrightInformation: carImageEdit.copyrightInformation,
                                    carModelID: carImageEdit.carModelID,
                                    isDraft: !user.isAdmin)
            return carImage.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                return carImage.save(on: req)
            }
        }.flatMap(to: ResolvedCarImage.self) { (carImage: CarImage) in
            return req.eventLoop.newSucceededFuture(result: carImage.resolvedCarImage())
        }
    }

    func patch(_ req: Request) throws -> Future<ResolvedCarImage> {
        return try req.parameters.next(CarImage.self).flatMap { carImage in
            return try req.content.decode(CarImage.self).flatMap { patchCarImage in
                carImage.copyrightInformation = patchCarImage.copyrightInformation
                carImage.carModelID = patchCarImage.carModelID
                carImage.updatedAt = Date()

                return carImage.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                    return carImage.save(on: req)
                }.flatMap(to: ResolvedCarImage.self) { carImage in
                    return req.eventLoop.newSucceededFuture(result: carImage.resolvedCarImage())
                }
            }
        }
    }

    func publish(_ req: Request) throws -> Future<ResolvedCarImage> {
        return try req.parameters.next(CarImage.self).flatMap { carImage in
            carImage.isDraft = false
            carImage.updatedAt = Date()
            return carImage.save(on: req).flatMap(to: ResolvedCarImage.self) { (carImage: CarImage) in
                return req.eventLoop.newSucceededFuture(result: carImage.resolvedCarImage())
            }
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarImage.self).flatMap { carImage in
            try carImage.removeFile()
            return carImage.delete(on: req).transform(to: .ok)
        }
    }

    func upload(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)

        return try req.parameters.next(CarImage.self).flatMap { carImage in
            // only allow allows on drafts when user is not admin
            if !user.isAdmin && !carImage.isDraft {
                return req.eventLoop.newFailedFuture(error: Abort(.forbidden,
                                                                  reason: "only admins can upload files for non draft images"))
            }
            return try req.content.decode(ImageUpload.self).flatMap(to: HTTPStatus.self) { imageUpload in
                carImage.updatedAt = Date()
                return carImage.save(on: req).flatMap { _ in
                    try carImage.updateWith(upload: imageUpload, req: req)
                    return req.eventLoop.newSucceededFuture(result: HTTPStatus.ok)
                }
            }
        }
    }

    func file(_ req: Request) throws -> Future<HTTPResponse> {
        return try req.parameters.next(CarImage.self).flatMap { carImage in
            guard let fileURL = carImage.filePathForImage() else {
                throw Abort(.notFound)
            }
            guard let fileData = try? Data(contentsOf: fileURL) else {
                throw Abort(.notFound)
            }
            let response = HTTPResponse(status: .ok,
                                        version: HTTPVersion(major: 1, minor: 1),
                                        headers: HTTPHeaders([("Content-Type", "image/jpg")]),
                                        body: HTTPBody(data: fileData))
            return req.eventLoop.newSucceededFuture(result: response)
        }
    }

}
