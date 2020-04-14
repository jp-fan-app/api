//
//  AccessMiddleware.swift
//  App
//
//  Created by Christoph Pageler on 19.08.18.
//


import Foundation
import Vapor


final class AccessMiddleware: Middleware, ServiceType {

    public init() {

    }

    public static func makeService(for worker: Container) throws -> AccessMiddleware {
        return AccessMiddleware()
    }

    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        if request.http.url.path.hasPrefix("/metrics") || request.http.url.path.hasPrefix("/public") {
            return try next.respond(to: request)
        }
        
        guard let accessToken = request.http.headers["x-access-token"].first else {
            throw Abort(.unauthorized, headers: HTTPHeaders(), reason: "x-access-token not set")
        }

        return Access.query(on: request).filter(\.token, .equal, accessToken).count().flatMap { count in
            guard count == 1 else {
                throw Abort(.unauthorized, headers: HTTPHeaders(), reason: "x-access-token not valid")
            }
            return try next.respond(to: request)
        }
    }

}
