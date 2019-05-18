//
//  AccessController.swift
//  App
//
//  Created by Christoph Pageler on 19.08.18.
//


import Vapor


final class AccessController {

    func index(_ req: Request) throws -> Future<[Access]> {
        return Access.query(on: req).all()
    }

    func show(_ req: Request) throws -> Future<Access> {
        return try req.parameters.next(Access.self)
    }

    func create(_ req: Request) throws -> Future<Access> {
        return try req.content.decode(AccessRequest.self).flatMap { accessRequest in
            return Access(name: accessRequest.name,
                          token: NSUUID().uuidString).save(on: req)
        }
    }

    func patch(_ req: Request) throws -> Future<Access> {
        return try req.parameters.next(Access.self).flatMap { access in
            return try req.content.decode(AccessRequest.self).flatMap { patchAccess in
                access.name = patchAccess.name
                access.updatedAt = Date()

                return access.save(on: req)
            }
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Access.self).flatMap { access in
            return access.delete(on: req)
        }.transform(to: .ok)
    }

    struct AccessRequest: Content {

        let name: String

    }

}
