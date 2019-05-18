//
//  ResetFromFileCommand.swift
//  App
//
//  Created by Christoph Pageler on 19.08.18.
//


import Foundation
import Vapor
import SwiftyJSON
import FluentMySQL


struct ResetFromFileCommand: Command {

    var arguments: [CommandArgument] {
        return []
    }

    var options: [CommandOption] {
        return [
            .value(name: "file",
                   short: "f",
                   default: nil,
                   help: [
                    "File"
                   ]),
            .value(name: "imagesFolder",
                   short: "i",
                   default: nil,
                   help: [
                    "Images Folder"
                ])
        ]
    }

    var help: [String] {
        return [
            "Aint nobody need help"
        ]
    }

    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        guard let jsonFile = context.options["file"] else {
            print("file not set")
            return context.container.eventLoop.newSucceededFuture(result: ())
        }
        guard FileManager.default.fileExists(atPath: jsonFile) else {
            print("file not found")
            return context.container.eventLoop.newSucceededFuture(result: ())
        }
        guard let imagesFolder = context.options["imagesFolder"] else {
            print("imagesFolder not set")
            return context.container.eventLoop.newSucceededFuture(result: ())
        }
        guard FileManager.default.fileExists(atPath: imagesFolder) else {
            print("imagesFolder not found")
            return context.container.eventLoop.newSucceededFuture(result: ())
        }

        let filePath = URL(fileURLWithPath: jsonFile).deletingLastPathComponent().path

        let jsonData = try Data(contentsOf: URL(fileURLWithPath: jsonFile))
        let json = JSON(data: jsonData)

        var resolvedSources: [String: String] = [:]

        let carImages = URL(fileURLWithPath: imagesFolder).appendingPathComponent("carImage")
        try FileManager.default.removeItem(at: carImages)
        try FileManager.default.createDirectory(at: carImages, withIntermediateDirectories: false, attributes: nil)

        return try clearCompleteDatabase(using: context)
        .then {
            for (key, source) in json["sources"].dictionary ?? [:] {
                guard let title = source["title"].string else {
                    print("WARNING: COULD NOT RESOLVE SOURCE TITLE")
                    continue
                }
                resolvedSources[key] = title
            }

            do {
                return try self.resolveCars(using: context,
                                            sources: resolvedSources,
                                            filePath: filePath,
                                            imagesFolder: imagesFolder,
                                            json: json["cars"].array ?? [])
            } catch {

            }
            return context.container.eventLoop.newSucceededFuture(result: ())
        }
    }

    private func clearCompleteDatabase(using context: CommandContext) throws -> EventLoopFuture<Void> {
        return context.container.withPooledConnection(to: .mysql)
        { (db: MySQLDatabase.Connection) -> EventLoopFuture<()> in
            Manufacturer.query(on: db).delete()
            .then {
                Device.query(on: db).delete()
            }
        }
    }

    private func resolveCars(using context: CommandContext,
                             sources: [String: String],
                             filePath: String,
                             imagesFolder: String,
                             json: [JSON]) throws -> EventLoopFuture<Void> {
        let promise = context.container.eventLoop.newPromise(Void.self)
        DispatchQueue(label: "resolveCars",
                      qos: .background,
                      attributes: .concurrent,
                      autoreleaseFrequency: .inherit,
                      target: nil).async
        {
            do {
                for carJSON in json {
                    try self.resolveCar(using: context,
                                        sources: sources,
                                        filePath: filePath,
                                        imagesFolder: imagesFolder,
                                        carJSON: carJSON).wait()
                }
            } catch {

            }
            promise.succeed()
        }
        return promise.futureResult
    }

    private func resolveCar(using context: CommandContext,
                            sources: [String: String],
                            filePath: String,
                            imagesFolder: String,
                            carJSON: JSON) throws -> EventLoopFuture<Void> {
        // resolve manufacturer
        guard let manufacturerJSON = carJSON["manufacturer"].string else {
            print("WARNING: COULD NOT RESOLVE MANUFACTURER")
            throw Abort(.notFound)
        }

        return resolveManufacturer(using: context, name: manufacturerJSON).flatMap(to: CarModel.self) { manufacturer in
            // resolve model
            guard let modelJSON = carJSON["model"].string else {
                print("WARNING: COULD NOT RESOLVE MODEL")
                throw Abort(.notFound)
            }
            guard let transmissionJSON = carJSON["transmission"].string else {
                print("WARNING: COULD NOT RESOLVE TRANSMISSION")
                throw Abort(.notFound)
            }
            guard let typeJSON = carJSON["type"].string else {
                print("WARNING: COULD NOT RESOLVE TYPE")
                throw Abort(.notFound)
            }

            return self.resolveCarModel(using: context, name: modelJSON,
                                        manufacturerID: manufacturer.id!,
                                        transmissionType: self.transmissionType(fromString: transmissionJSON),
                                        axleType: self.axleType(fromString: typeJSON))
        }.flatMap { carModel -> EventLoopFuture<CarModel> in
            let promise = context.container.eventLoop.newPromise(CarModel.self)

            DispatchQueue(label: "resolveCarImages",
                          qos: .background,
                          attributes: .concurrent,
                          autoreleaseFrequency: .inherit,
                          target: nil).async
            {
                do {
                    for imageJSON in carJSON["images"].array ?? [] {
                        _ = try self.resolveCarImage(using: context,
                                                                sources: sources,
                                                                filePath: filePath,
                                                                carModelID: carModel.id!,
                                                                imagesFolder: imagesFolder,
                                                                carImageJSON: imageJSON)
                        .flatMap { (carImage, isMain) -> EventLoopFuture<CarImage> in
                            if isMain {
                                carModel.mainImageID = carImage.id
                                carModel.updatedAt = Date()
                                return context.container.withPooledConnection(to: .mysql)
                                { (db: MySQLDatabase.Connection) -> EventLoopFuture<CarModel> in
                                    return carModel.save(on: db)
                                }.flatMap(to: CarImage.self) { carModel in
                                    return context.container.eventLoop.newSucceededFuture(result: carImage)
                                }
                            } else {
                                return context.container.eventLoop.newSucceededFuture(result: carImage)
                            }
                        }.wait()
                    }
                } catch {

                }
                promise.succeed(result: carModel)
            }

            return promise.futureResult
        }.flatMap { carModel -> EventLoopFuture<CarModel> in
            let promise = context.container.eventLoop.newPromise(CarModel.self)

            DispatchQueue(label: "resolveCarImages",
                          qos: .background,
                          attributes: .concurrent,
                          autoreleaseFrequency: .inherit,
                          target: nil).async
            {
                do {
                    for stagesJSON in carJSON["stages"].array ?? [] {
                        _ = try self.resolveCarStage(using: context,
                                                     carModelID: carModel.id!,
                                                     carStageJSON: stagesJSON).wait()
                    }
                } catch {

                }
                promise.succeed(result: carModel)
            }

            return promise.futureResult
        }.transform(to: ())

    }

    private func resolveManufacturer(using context: CommandContext,
                                     name: String) -> EventLoopFuture<Manufacturer> {
        return context.container.withPooledConnection(to: .mysql)
        { (db: MySQLDatabase.Connection) -> EventLoopFuture<Manufacturer> in
            return Manufacturer.query(on: db).filter(\.name, .equal, name).first().flatMap { manufacturer in
                if let manufacturer = manufacturer {
                    return context.container.eventLoop.newSucceededFuture(result: manufacturer)
                } else {
                    return Manufacturer(name: name).create(on: db)
                }
            }
        }
    }

    private func resolveCarModel(using context: CommandContext,
                                 name: String,
                                 manufacturerID: Int,
                                 transmissionType: CarModel.TransmissionType,
                                 axleType: CarModel.AxleType) -> EventLoopFuture<CarModel> {
        return context.container.withPooledConnection(to: .mysql)
        { (db: MySQLDatabase.Connection) -> EventLoopFuture<CarModel> in
            return CarModel(name: name,
                            manufacturerID: manufacturerID,
                            transmissionType: transmissionType,
                            axleType: axleType,
                            mainImageID: nil).create(on: db)
        }
    }

    private func resolveCarImage(using context: CommandContext,
                                 sources: [String: String],
                                 filePath: String,
                                 carModelID: Int,
                                 imagesFolder: String,
                                 carImageJSON: JSON) throws -> EventLoopFuture<(CarImage, Bool)> {
        guard let urlJSON = carImageJSON["url"].string else {
            print("WARNING: COULD NOT RESOLVE URL")
            throw Abort(.notFound)
        }
        let isMain = carImageJSON["main"].bool ?? false
        let sourceKey = carImageJSON["source"].string

        let absoluteImageFileURL = URL(fileURLWithPath: filePath).appendingPathComponent(urlJSON)
        if !FileManager.default.fileExists(atPath: absoluteImageFileURL.path) {
            print("WARNING: COULD NOT FIND IMAGE URL")
            throw Abort(.notFound)
        }
        let imageData = try Data(contentsOf: absoluteImageFileURL)

        let copyrightInformation = sources[sourceKey ?? ""] ?? ""

        return try context.container.withPooledConnection(to: .mysql)
        { (db: MySQLDatabase.Connection) -> EventLoopFuture<CarImage> in
            CarImage(copyrightInformation: copyrightInformation,
                     carModelID: carModelID).create(on: db)
        }.map { carImage in
            if absoluteImageFileURL.path.contains("no_image.jpg") {
//                print("skip no images")
            } else {
                let newFilePath = URL(fileURLWithPath: imagesFolder)
                    .appendingPathComponent("carImage").appendingPathComponent("\(carImage.id!).jpg")
                try imageData.write(to: newFilePath)
            }
            return (carImage, isMain)
        }
    }

    private func resolveCarStage(using context: CommandContext,
                                 carModelID: Int,
                                 carStageJSON: JSON) throws -> EventLoopFuture<CarStage> {
        guard let titleJSON = carStageJSON["title"].string else {
            print("WARNING: COULD NOT RESOLVE TITLE")
            throw Abort(.notFound)
        }
        let description = carStageJSON["description"].string
        let isStock = carStageJSON["isStock"].bool ?? false
        let youtubeId = carStageJSON["youtubeId"].string
        let ps = carStageJSON["ps"].double
        let nm = carStageJSON["nm"].double

        return context.container.withPooledConnection(to: .mysql)
        { (db: MySQLDatabase.Connection) -> EventLoopFuture<CarStage> in
            return CarStage(name: titleJSON,
                            description: description,
                            isStock: isStock,
                            ps: ps,
                            nm: nm,
                            carModelID: carModelID)
            .save(on: db).flatMap { carStage -> EventLoopFuture<CarStage> in
                if let youtubeId = youtubeId {
                    return YoutubeVideo.query(on: db).filter(\.videoID, .equal, youtubeId).first().flatMap { youtubeVideo in
                        if let youtubeVideo = youtubeVideo {
                            return CarStageYoutubeVideo(id: nil,
                                                        youtubeVideoID: youtubeVideo.id!,
                                                        carStageID: carStage.id!)
                            .save(on: db).flatMap(to: CarStage.self) { _ in
                                return context.container.eventLoop.newSucceededFuture(result: carStage)
                            }
                        } else {
                            print("could not found \(youtubeId)")
                            return context.container.eventLoop.newSucceededFuture(result: carStage)
                        }
                    }
                } else {
                    return context.container.eventLoop.newSucceededFuture(result: carStage)
                }
            }.flatMap { carStage in
                let promise = context.container.eventLoop.newPromise(CarStage.self)

                DispatchQueue(label: "resolveStageTiming",
                              qos: .background,
                              attributes: .concurrent,
                              autoreleaseFrequency: .inherit,
                              target: nil).async
                    {
                        do {
                            for timingJSON in carStageJSON["timings"].array ?? [] {
                                _ = try self.resolveStageTiming(using: context,
                                                                carStageID: carStage.id!,
                                                                stageTimingJSON: timingJSON).wait()
                            }
                        } catch {

                        }
                        promise.succeed(result: carStage)
                }
                return promise.futureResult
            }
        }
    }

    private func resolveStageTiming(using context: CommandContext,
                                    carStageID: Int,
                                    stageTimingJSON: JSON) throws -> EventLoopFuture<StageTiming> {
        guard let range = stageTimingJSON["range"].string else {
            print("WARNING: COULD NOT RESOLVE RANGE")
            throw Abort(.notFound)
        }
        var seconds: [Double] = []
        for secondJSON in stageTimingJSON["seconds"].array ?? [] {
            if let secondDouble = secondJSON.double {
                seconds.append(secondDouble)
            }
        }

        return context.container.withPooledConnection(to: .mysql)
        { (db: MySQLDatabase.Connection) -> EventLoopFuture<StageTiming> in
            return StageTiming(range: range,
                second1: seconds[safe: 0],
                second2: seconds[safe: 1],
                second3: seconds[safe: 2],
                stageID: carStageID).save(on: db)
        }
    }

    private func transmissionType(fromString: String) -> CarModel.TransmissionType {
        switch fromString {
        case "automatic": return .automatic
        case "manual": return .manual
        default:
            print("WARNING: COULD NOT RESOLVE TRANSMISSION TYPE \(fromString)")
            abort()
        }
    }

    private func axleType(fromString: String) -> CarModel.AxleType {
        switch fromString {
        case "all": return .all
        case "rear": return .rear
        case "front": return .front
        default:
            print("WARNING: COULD NOT RESOLVE AXLE TYPE \(fromString)")
            abort()
        }
    }

}
