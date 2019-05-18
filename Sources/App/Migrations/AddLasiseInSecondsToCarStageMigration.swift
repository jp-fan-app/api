//
//  AddLasiseInSecondsToCarStageMigration.swift
//  App
//
//  Created by Christoph Pageler on 18.05.19.
//


import FluentMySQL


struct AddLasiseInSecondsToCarStageMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.update(CarStage.self, on: conn) { builder in
            builder.field(for: \.lasiseInSeconds)
        }
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.update(CarStage.self, on: conn) { builder in
            builder.deleteField(for: \.lasiseInSeconds)
        }
    }

}
