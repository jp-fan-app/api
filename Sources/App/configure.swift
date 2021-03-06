//
//  configure.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import FluentMySQL
import Authentication
import Random
import Vapor


public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // Providers
    try services.register(FluentMySQLProvider())
    try services.register(AuthenticationProvider())


    // Server Settings
    var nioServerConfig = NIOServerConfig.default()
    nioServerConfig.maxBodySize = 5 * 1024 * 1024
    nioServerConfig.hostname = "0.0.0.0"
    services.register(nioServerConfig)


    // Fluent Configuration (Droplet Single Core Problem)
    let poolConfig = DatabaseConnectionPoolConfig(maxConnections: 16)
    services.register(poolConfig)


    // Router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)


    services.register(AccessMiddleware.self)

    // Middlewares
    var middlewares = MiddlewareConfig()
    middlewares.use(ErrorMiddleware.self)
    middlewares.use(AccessMiddleware.self)
    services.register(middlewares)

    
    // Database
    let hostname = ProcessInfo.processInfo.environment["MYSQL_HOST"] ?? "localhost"
    let username = ProcessInfo.processInfo.environment["MYSQL_USER"] ?? "jpfanapp_dev"
    let password = ProcessInfo.processInfo.environment["MYSQL_PASSWORD"] ?? "jpfanapp_dev"
    let database = ProcessInfo.processInfo.environment["MYSQL_DATABASE"] ?? "jpfanapp_dev"

    let config = MySQLDatabaseConfig(hostname: hostname,
                                     port: 3306,
                                     username: username,
                                     password: password,
                                     database: database,
                                     capabilities: .default,
                                     characterSet: .utf8_general_ci,
                                     transport: .cleartext)
    let mysql = MySQLDatabase(config: config)
    var databases = DatabasesConfig()
    databases.add(database: mysql, as: .mysql)
    services.register(databases)


    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: UserToken.self, database: .mysql)
    migrations.add(model: Manufacturer.self, database: .mysql)
    migrations.add(model: CarModel.self, database: .mysql)
    migrations.add(model: CarImage.self, database: .mysql)
    migrations.add(model: CarStage.self, database: .mysql)
    migrations.add(model: StageTiming.self, database: .mysql)
    migrations.add(model: YoutubeVideo.self, database: .mysql)
    migrations.add(model: Device.self, database: .mysql)
    migrations.add(model: NotificationPreference.self, database: .mysql)
    migrations.add(migration: DevicesPushTokenUniqueKeyMigration.self, database: .mysql)
    migrations.add(model: CarStageYoutubeVideo.self, database: .mysql)
//    migrations.add(migration: RemoveStageIDFromYoutubeVideoMigration.self, database: .mysql)
    migrations.add(migration: AddDeleteCascadingForeignKeysMigration.self, database: .mysql)
//    migrations.add(migration: AddTimestampsMigration.self, database: .mysql)
    migrations.add(model: Access.self, database: .mysql)
    migrations.add(model: VideoSerie.self, database: .mysql)
    migrations.add(model: VideoSerieYoutubeVideo.self, database: .mysql)
    migrations.add(migration: AddVideoSeriesDeleteCascadingForeignKeysMigration.self, database: .mysql)
    migrations.add(migration: AddLasiseInSecondsToCarStageMigration.self, database: .mysql)
    services.register(migrations)


    // Commands
    var commandConfig = CommandConfig.default()
    commandConfig.use(UpdateYoutubeVideosCommand(), as: "updateYoutubeVideos")
    commandConfig.use(ResetFromFileCommand(), as: "resetFromFile")
    services.register(commandConfig)

}
