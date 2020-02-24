//
//  AuthController.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor
import Fluent
import Crypto
import Random


final class AuthController {

    private static func passwordSalt() -> String {
        return ProcessInfo.processInfo.environment["AUTH_PASSWORD_SALT"] ?? ""
    }

    struct LoginResult: Content {

        let token: String
        let isAdmin: Bool

    }

    func login(_ req: Request) throws -> Future<LoginResult> {
        return try req.content.decode(LoginRequest.self).flatMap { loginRequest in
            let hashedPassword = try AuthController.hashedPassword(req: req, loginRequest.password)

            return User.query(on: req)
                .filter(\.email == loginRequest.email)
                .filter(\.passwordHash == hashedPassword)
                .first()
                .flatMap
            { existingUser in
                guard let user = existingUser, let userID = user.id else {
                    throw Abort(.unauthorized, reason: "invalid login", identifier: nil)
                }

                let newToken = UserToken(string: UUID().uuidString, userID: userID)
                return newToken.save(on: req).map { userToken in
                    return LoginResult(token: userToken.string, isAdmin: user.isAdmin)
                }
            }
        }
    }

    static func hashedPassword(req: Request, _ password: String) throws -> String {
        let digest = try req.make(BCryptDigest.self)
        let salt = passwordSalt()
        return try digest.hash(password, salt: salt)
    }

    func changePassword(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.content.decode(ChangePasswordRequest.self).flatMap { changePasswordRequest in
            let user = try req.requireAuthenticated(User.self)
            let hashedPassword = try AuthController.hashedPassword(req: req, changePasswordRequest.password)
            user.passwordHash = hashedPassword
            user.updatedAt = Date()

            return user.save(on: req).transform(to: .ok)
        }
    }

}
