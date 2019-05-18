//
//  CarImagesController.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor


final class CarImageController {

    func index(_ req: Request) throws -> Future<[ResolvedCarImage]> {
        return CarImage.query(on: req).all().map(to: [ResolvedCarImage].self) { carImages in
            return carImages.compactMap({ $0.resolvedCarImage() })
        }
    }

    func show(_ req: Request) throws -> Future<ResolvedCarImage> {
        return try req.parameters.next(CarImage.self).map(to: ResolvedCarImage.self, { $0.resolvedCarImage() })
    }

    func create(_ req: Request) throws -> Future<ResolvedCarImage> {
        return try req.content.decode(CarImage.self).flatMap { carImage in
            return carImage.ensureRelations(eventLoop: req.eventLoop, on: req).flatMap { _ in
                return carImage.save(on: req)
            }
        }.flatMap(to: ResolvedCarImage.self) { carImage in
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

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarImage.self).flatMap { carImage in
            try carImage.removeFile()
            return carImage.delete(on: req).transform(to: .ok)
        }
    }

    func upload(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(CarImage.self).flatMap { carImage in
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
