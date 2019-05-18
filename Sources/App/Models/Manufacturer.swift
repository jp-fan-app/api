//
//  Manufacturer.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import FluentMySQL
import Vapor


final class Manufacturer: MySQLModel {

    var id: Int?
    var name: String
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var models: Children<Manufacturer, CarModel> {
        return children(\.manufacturerID)
    }

}


extension Manufacturer: Migration { }


extension Manufacturer: Content { }


extension Manufacturer: Parameter { }
