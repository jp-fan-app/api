//
//  ManufacturerController.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor
import FluentMySQL


final class ManufacturerController {

    func index(_ req: Request) throws -> Future<[Manufacturer]> {
        return Manufacturer
            .query(on: req)
            .filter(\.isDraft == false)
            .all()
    }

    func indexDraft(_ req: Request) throws -> Future<[Manufacturer]> {
        return Manufacturer
            .query(on: req)
            .filter(\.isDraft == true)
            .all()
    }

    func show(_ req: Request) throws -> Future<Manufacturer> {
        return try req.parameters.next(Manufacturer.self)
    }

    func create(_ req: Request) throws -> Future<Manufacturer> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(ManufacturerEdit.self).flatMap { manufacturer in
            let manufacturer = Manufacturer(name: manufacturer.name, isDraft: !user.isAdmin)
            return manufacturer.save(on: req)
        }
    }

    func patch(_ req: Request) throws -> Future<Manufacturer> {
        return try req.parameters.next(Manufacturer.self).flatMap { manufacturer in
            return try req.content.decode(ManufacturerEdit.self).flatMap { patchManufacturer in
                manufacturer.name = patchManufacturer.name
                manufacturer.updatedAt = Date()
                return manufacturer.save(on: req)
            }
        }
    }

    func publish(_ req: Request) throws -> Future<Manufacturer> {
        return try req.parameters.next(Manufacturer.self).flatMap { manufacturer in
            manufacturer.isDraft = false
            manufacturer.updatedAt = Date()
            return manufacturer.save(on: req)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Manufacturer.self).flatMap { manufacturer in
            return manufacturer.delete(on: req)
        }.transform(to: .ok)
    }

    func models(_ req: Request) throws -> Future<[CarModel]> {
        return try req.parameters.next(Manufacturer.self).flatMap(to: [CarModel].self) { manufacturer in
            return try manufacturer.models
                .query(on: req)
                .filter(\.isDraft == false)
                .all()
        }
    }

}
