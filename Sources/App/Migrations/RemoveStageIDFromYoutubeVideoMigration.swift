//
//  RemoveStageIDFromYoutubeVideoMigration.swift
//  App
//
//  Created by Christoph Pageler on 16.08.18.
//


import FluentMySQL


struct RemoveStageIDFromYoutubeVideoMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let query = "ALTER TABLE `YoutubeVideo` DROP `stageID`;"
        return conn.simpleQuery(query).transform(to: ())
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        let query = "ALTER TABLE `YoutubeVideo` ADD `stageID` BIGINT(20)  NULL  DEFAULT NULL  AFTER `publishedAt`;"
        return conn.simpleQuery(query).transform(to: ())
    }

}
