//
//  AddVideoSeriesDeleteCascadingForeignKeysMigration.swift
//  App
//
//  Created by Christoph Pageler on 25.10.18.
//


import FluentMySQL


struct AddVideoSeriesDeleteCascadingForeignKeysMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.simpleQuery("ALTER TABLE `VideoSerie_YoutubeVideo` ADD CONSTRAINT `VideoSerie_YoutubeVideoYoutubeVideoDelete` FOREIGN KEY (`youtubeVideoID`) REFERENCES `YoutubeVideo` (`id`) ON DELETE CASCADE;")
            .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerie_YoutubeVideo` ADD CONSTRAINT `VideoSerie_YoutubeVideoVideoSerieDelete` FOREIGN KEY (`videoSerieID`) REFERENCES `VideoSerie` (`id`) ON DELETE CASCADE;") }
            .transform(to: ())
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.simpleQuery("")
            .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerie_YoutubeVideo` DROP FOREIGN KEY `VideoSerie_YoutubeVideoYoutubeVideoDelete`;") }
            .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerie_YoutubeVideo` DROP FOREIGN KEY `VideoSerie_YoutubeVideoVideoSerieDelete`;") }
            .transform(to: ())

    }

}
