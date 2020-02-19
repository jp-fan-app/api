//
//  AddIsDraftToModelsMigration.swift
//  App
//
//  Created by Christoph Pageler on 17.02.20.
//


import FluentMySQL


struct AddIsDraftToModelsMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.simpleQuery("ALTER TABLE `CarImage` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `carModelID`;" )
        .then { _ in conn.simpleQuery("ALTER TABLE `CarModel` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `mainImageID`;" ) }
        .then { _ in conn.simpleQuery("ALTER TABLE `CarStage` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `carModelID`;" ) }
        .then { _ in conn.simpleQuery("ALTER TABLE `CarStage_YoutubeVideo` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `carStageID`;" ) }
        .then { _ in conn.simpleQuery("ALTER TABLE `Manufacturer` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `name`;" ) }
        .then { _ in conn.simpleQuery("ALTER TABLE `StageTiming` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `stageID`;" ) }
        .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerie` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `isPublic`;" ) }
        .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerie_YoutubeVideo` ADD `isDraft` TINYINT(1)  NOT NULL  DEFAULT '0'  AFTER `description`;" ) }
        .transform(to: ())
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.simpleQuery("ALTER TABLE `CarImageDROP `isDraft`;" )
            .then { _ in conn.simpleQuery("ALTER TABLE `CarModelDROP `isDraft`;" ) }
            .then { _ in conn.simpleQuery("ALTER TABLE `CarStageDROP `isDraft`;" ) }
            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage_YoutubeVideoDROP `isDraft`;" ) }
            .then { _ in conn.simpleQuery("ALTER TABLE `ManufacturerDROP `isDraft`;" ) }
            .then { _ in conn.simpleQuery("ALTER TABLE `StageTimingDROP `isDraft`;" ) }
            .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerieDROP `isDraft`;" ) }
            .then { _ in conn.simpleQuery("ALTER TABLE `VideoSerie_YoutubeVideoDROP `isDraft`;" ) }
            .transform(to: ())

    }

}
