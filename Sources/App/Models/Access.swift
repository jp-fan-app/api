//
//  Access.swift
//  App
//
//  Created by Christoph Pageler on 19.08.18.
//


import FluentMySQL
import Vapor
import SwiftyJSON


final class Access: MySQLModel {

    var id: Int?
    var name: String
    var token: String
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         name: String,
         token: String) {
        self.id = id
        self.name = name
        self.token = token
        self.createdAt = Date()
        self.updatedAt = nil
    }

}


extension Access: Migration { }


extension Access: Content { }


extension Access: Parameter { }
