//
//  AddIsAdminToUserMigration.swift
//  App
//
//  Created by Christoph Pageler on 17.02.20.
//


import FluentMySQL


struct AddIsAdminToUserMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let query = "ALTER TABLE `User` ADD `isAdmin` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `passwordHash`;"
        return conn.simpleQuery(query).transform(to: ())
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let query = "ALTER TABLE `User` DROP `isAdmin`;"
        return conn.simpleQuery(query).transform(to: ())
    }

}
