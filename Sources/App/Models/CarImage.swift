//
//  CarImage.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import FluentMySQL
import Vapor


final class CarImage: MySQLModel {

    var id: Int?
    var copyrightInformation: String
    var carModelID: CarModel.ID
    var isDraft: Bool
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         copyrightInformation: String,
         carModelID: CarModel.ID,
         isDraft: Bool) {
        self.id = id
        self.copyrightInformation = copyrightInformation
        self.carModelID = carModelID
        self.isDraft = isDraft
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var carModel: Parent<CarImage, CarModel> {
        return parent(\.carModelID)
    }

    func ensureRelations(eventLoop: EventLoop, on db: DatabaseConnectable) -> EventLoopFuture<Void> {
        return CarModel.find(carModelID, on: db).flatMap { carModel in
            guard carModel != nil else {
                throw Abort(.notFound, headers: HTTPHeaders(), reason: "carModelID not found")
            }

            return eventLoop.newSucceededFuture(result: ())
        }
    }

    func updateWith(upload: ImageUpload, req: Request) throws {
        guard let path = filePathForImage() else {
            throw Abort(.internalServerError, reason: "unable to get upload path", identifier: nil)
        }

        let folder = path.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        }

        try upload.image.write(to: path)
    }

    func filePathForImage() -> URL? {
        guard let imagesFolder = ProcessInfo.processInfo.environment["IMAGES_FOLDER"] else { return nil }
        guard let carID = id else { return nil }

        let imagesFolderURL = URL(fileURLWithPath: imagesFolder)
        return imagesFolderURL
            .appendingPathComponent("carImage")
            .appendingPathComponent("\(carID).jpg")
    }

    func resolvedCarImage() -> ResolvedCarImage {
        var hasUpload = false
        if let fileURL = filePathForImage() {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                hasUpload = true
            }
        }

        return ResolvedCarImage(id: id,
                                copyrightInformation: copyrightInformation,
                                carModelID: carModelID,
                                hasUpload: hasUpload,
                                isDraft: isDraft,
                                createdAt: createdAt,
                                updatedAt: updatedAt)
    }

    func removeFile() throws {
        guard let filePath = filePathForImage() else { return }
        guard FileManager.default.fileExists(atPath: filePath.path) else { return }

        try FileManager.default.removeItem(at: filePath)
    }

}


extension CarImage: Migration { }


extension CarImage: Content { }


extension CarImage: Parameter { }


struct CarImageEdit: Content {

    var copyrightInformation: String
    var carModelID: CarModel.ID

}


struct ResolvedCarImage: Content {

    var id: Int?
    var copyrightInformation: String
    var carModelID: CarModel.ID
    var hasUpload: Bool
    var isDraft: Bool
    var createdAt: Date?
    var updatedAt: Date?

}


struct ImageUpload: Content {

    var image: Data

}


struct ImageDownload: Content {

    var image: Data
}
