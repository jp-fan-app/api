//
//  UserController.swift
//  App
//
//  Created by Christoph Pageler on 24.02.20.
//


import Vapor


final class UserController {

    struct UserStruct: Content {

        let id: Int?
        let name: String
        let email: String
        let isAdmin: Bool

        static func fromUser(_ user: User) -> UserStruct {
            UserStruct(id: user.id, name: user.name, email: user.email, isAdmin: user.isAdmin)
        }

    }

    struct EditUserRequest: Content {

        let name: String
        let email: String
        let password: String
        let isAdmin: Bool

    }

    func index(_ req: Request) throws -> Future<[UserStruct]> {
        return User.query(on: req).all().map { $0.map({ UserStruct.fromUser($0)} )}
    }

    func show(_ req: Request) throws -> Future<UserStruct> {
        return try req.parameters.next(User.self).map({ UserStruct.fromUser($0)})
    }

    func create(_ req: Request) throws -> Future<UserStruct> {
        return try req.content.decode(EditUserRequest.self).flatMap { createUser in
            let hashedPassword = try AuthController.hashedPassword(req: req, createUser.password)
            let user = User(name: createUser.name,
                            email: createUser.email,
                            passwordHash: hashedPassword)
            return user.save(on: req).map({ UserStruct.fromUser($0)})
        }
    }

    func patch(_ req: Request) throws -> Future<UserStruct> {
        return try req.content.decode(EditUserRequest.self).flatMap { updateUser in
            return try req.parameters.next(User.self).flatMap { user in
                user.name = updateUser.name
                user.email = updateUser.email
                user.isAdmin = updateUser.isAdmin
                return user.save(on: req).map({ UserStruct.fromUser($0)})
            }
        }
    }

    struct ChangePasswordRequest: Content {

        let password: String

    }

    func changePassword(_ req: Request) throws -> Future<UserStruct> {
        return try req.content.decode(ChangePasswordRequest.self).flatMap { changePassword in
            return try req.parameters.next(User.self).flatMap { user in
                let hashedPassword = try AuthController.hashedPassword(req: req, changePassword.password)
                user.passwordHash = hashedPassword
                return user.save(on: req).map({ UserStruct.fromUser($0)})
            }
        }
    }

    func showTokens(_ req: Request) throws -> Future<[UserToken]> {
        return try req.parameters.next(User.self).flatMap { user in
            return try user.tokens.query(on: req).all()
        }
    }

    func deleteToken(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).flatMap { user in
            return try user.tokens.query(on: req).delete().transform(to: .ok)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(User.self).flatMap { user in
            return try user.tokens.query(on: req).delete().flatMap { _ in
                return user.delete(on: req)
            }
        }.transform(to: .ok)
    }

}
