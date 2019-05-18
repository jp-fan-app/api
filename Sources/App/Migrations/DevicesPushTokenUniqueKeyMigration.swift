//
//  DevicesPushTokenUniqueKeyMigration.swift
//  App
//
//  Created by Christoph Pageler on 14.08.18.
//


import FluentMySQL


struct DevicesPushTokenUniqueKeyMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let query = "ALTER TABLE `Device` ADD UNIQUE INDEX `pushTokenUniqueKey` (`pushToken`);"
        return conn.simpleQuery(query).transform(to: ())
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let query = "ALTER TABLE `Device` DROP INDEX `pushTokenUniqueKey`;"
        return conn.simpleQuery(query).transform(to: ())
    }

}
