//
//  AddDeleteCascadingForeignKeysMigration.swift
//  App
//
//  Created by Christoph Pageler on 17.08.18.
//


import FluentMySQL


struct AddDeleteCascadingForeignKeysMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.simpleQuery("ALTER TABLE `CarModel` ADD CONSTRAINT `CarModelManufacturerDelete` FOREIGN KEY (`manufacturerID`) REFERENCES `Manufacturer` (`id`) ON DELETE CASCADE;")
            .then { _ in conn.simpleQuery("ALTER TABLE `CarModel` ADD CONSTRAINT `CarModelMainImageSetNull` FOREIGN KEY (`mainImageID`) REFERENCES `CarImage` (`id`) ON DELETE SET NULL;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `CarImage` ADD CONSTRAINT `CarImageCarModelDelete` FOREIGN KEY (`carModelID`) REFERENCES `CarModel` (`id`) ON DELETE CASCADE;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage` ADD CONSTRAINT `CarStageCarModelDelete` FOREIGN KEY (`carModelID`) REFERENCES `CarModel` (`id`) ON DELETE CASCADE;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage_YoutubeVideo` ADD CONSTRAINT `CarStage_YoutubeVideoYoutubeVideoDelete` FOREIGN KEY (`youtubeVideoID`) REFERENCES `YoutubeVideo` (`id`) ON DELETE CASCADE;") }
            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage_YoutubeVideo` ADD CONSTRAINT `CarStage_YoutubeVideoCarStageDelete` FOREIGN KEY (`carStageID`) REFERENCES `CarStage` (`id`) ON DELETE CASCADE;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `NotificationPreference` ADD CONSTRAINT `NotificationPreferenceDeviceDelete` FOREIGN KEY (`deviceID`) REFERENCES `Device` (`id`) ON DELETE CASCADE;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `StageTiming` ADD CONSTRAINT `StageTimingCarStageDelete` FOREIGN KEY (`stageID`) REFERENCES `CarStage` (`id`) ON DELETE CASCADE;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `UserToken` ADD CONSTRAINT `UserTokenUserDelete` FOREIGN KEY (`userID`) REFERENCES `User` (`id`) ON DELETE CASCADE;") }
            .transform(to: ())
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return conn.simpleQuery("")
            .then { _ in conn.simpleQuery("ALTER TABLE `CarModel` DROP FOREIGN KEY `CarModelManufacturerDelete`;") }
            .then { _ in conn.simpleQuery("ALTER TABLE `CarModel` DROP FOREIGN KEY `CarModelMainImageSetNull`;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `CarImage` DROP FOREIGN KEY `CarImageCarModelDelete`;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage` DROP FOREIGN KEY `CarStageCarModelDelete`;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage_YoutubeVideo` DROP FOREIGN KEY `CarStage_YoutubeVideoYoutubeVideoDelete`;") }
            .then { _ in conn.simpleQuery("ALTER TABLE `CarStage_YoutubeVideo` DROP FOREIGN KEY `CarStage_YoutubeVideoCarStageDelete`;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `NotificationPreference` DROP FOREIGN KEY `NotificationPreferenceDeviceDelete`;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `StageTiming` DROP FOREIGN KEY `StageTimingCarStageDelete`;") }

            .then { _ in conn.simpleQuery("ALTER TABLE `UserToken` DROP FOREIGN KEY `UserTokenUserDelete`;") }
            .transform(to: ())

    }

}
