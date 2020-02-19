//
//  User.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//

import FluentMySQL
import Vapor
import Authentication


final class User: MySQLModel {
    
    var id: Int?
    var name: String
    var email: String
    var passwordHash: String
    var isAdmin: Bool
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.isAdmin = false
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var tokens: Children<User, UserToken> {
        return children(\.userID)
    }

}


extension User: Migration { }


extension User: Content { }


extension User: Parameter { }


extension User: TokenAuthenticatable {

    typealias TokenType = UserToken

}


final class UserToken: MySQLModel {

    var id: Int?
    var string: String
    var userID: User.ID
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil, string: String, userID: User.ID) {
        self.id = id
        self.string = string
        self.userID = userID
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var user: Parent<UserToken, User> {
        return parent(\.userID)
    }

}


extension UserToken: Migration { }


extension UserToken: Content { }


extension UserToken: Parameter { }


extension UserToken: Token {

    typealias UserType = User

    static var tokenKey: WritableKeyPath<UserToken, String> {
        return \.string
    }

    static var userIDKey: WritableKeyPath<UserToken, User.ID> {
        return \.userID
    }

}


struct LoginRequest: Content {

    var email: String
    var password: String

}


struct ChangePasswordRequest: Content {

    var password: String

}
