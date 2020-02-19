//
//  AdminMiddleware.swift
//  App
//
//  Created by Christoph Pageler on 18.02.20.
//


import Foundation
import Vapor


final class AdminMiddleware: Middleware, ServiceType {

    public init() {

    }

    public static func makeService(for worker: Container) throws -> AdminMiddleware {
        return AdminMiddleware()
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let user = try request.requireAuthenticated(User.self)
        if !user.isAdmin {
            throw Abort(.forbidden, headers: HTTPHeaders(), reason: "user is not an admin")
        }
        return try next.respond(to: request)
    }

}
