//
//  AddTimestampsMigration.swift
//  App
//
//  Created by Christoph Pageler on 19.08.18.
//


import FluentMySQL


struct AddTimestampsMigration: MySQLMigration {

    static func prepare(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.update(CarImage.self, on: conn) { builder in
            builder.field(for: \.createdAt)
            builder.field(for: \.updatedAt)
        }.flatMap { _ in
            return MySQLDatabase.update(CarModel.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(CarStage.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(Manufacturer.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(StageTiming.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(User.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(YoutubeVideo.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(CarStageYoutubeVideo.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(Device.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(NotificationPreference.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(UserToken.self, on: conn) { builder in
                builder.field(for: \.createdAt)
                builder.field(for: \.updatedAt)
            }
        }
    }

    static func revert(on conn: MySQLConnection) -> EventLoopFuture<Void> {
        return MySQLDatabase.update(CarImage.self, on: conn) { builder in
            builder.deleteField(for: \.createdAt)
            builder.deleteField(for: \.updatedAt)
        }.flatMap { _ in
            return MySQLDatabase.update(CarModel.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(CarStage.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(Manufacturer.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(StageTiming.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(User.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(YoutubeVideo.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(CarStageYoutubeVideo.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(Device.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(NotificationPreference.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }.flatMap { _ in
            return MySQLDatabase.update(UserToken.self, on: conn) { builder in
                builder.deleteField(for: \.createdAt)
                builder.deleteField(for: \.updatedAt)
            }
        }
    }

}
