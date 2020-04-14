//
//  configure.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import FluentMySQL
import Authentication
import Random
import VaporMonitoring
import Vapor


public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // Providers
    try services.register(FluentMySQLProvider())
    try services.register(AuthenticationProvider())
    services.register(MetricsMiddleware(), as: MetricsMiddleware.self)


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
    let prometheusService = VaporPrometheus(router: router, services: &services, route: "metrics")
    services.register(prometheusService)
    services.register(router, as: Router.self)


    services.register(AccessMiddleware.self)

    // Middlewares
    var middlewares = MiddlewareConfig()
    middlewares.use(MetricsMiddleware.self)
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
    migrations.add(model: User.self, database: DatabaseIdentifier<User.Database>.mysql)
    migrations.add(model: UserToken.self, database: DatabaseIdentifier<UserToken.Database>.mysql)
    migrations.add(model: Manufacturer.self, database: DatabaseIdentifier<Manufacturer.Database>.mysql)
    migrations.add(model: CarModel.self, database: DatabaseIdentifier<CarModel.Database>.mysql)
    migrations.add(model: CarImage.self, database: DatabaseIdentifier<CarImage.Database>.mysql)
    migrations.add(model: CarStage.self, database: DatabaseIdentifier<CarStage.Database>.mysql)
    migrations.add(model: StageTiming.self, database: DatabaseIdentifier<StageTiming.Database>.mysql)
    migrations.add(model: YoutubeVideo.self, database: DatabaseIdentifier<YoutubeVideo.Database>.mysql)
    migrations.add(model: Device.self, database: DatabaseIdentifier<Device.Database>.mysql)
    migrations.add(model: NotificationPreference.self, database: DatabaseIdentifier<NotificationPreference.Database>.mysql)
    migrations.add(migration: DevicesPushTokenUniqueKeyMigration.self, database: .mysql)
    migrations.add(model: CarStageYoutubeVideo.self, database: .mysql)
//    migrations.add(migration: RemoveStageIDFromYoutubeVideoMigration.self, database: .mysql)
    migrations.add(migration: AddDeleteCascadingForeignKeysMigration.self, database: .mysql)
//    migrations.add(migration: AddTimestampsMigration.self, database: .mysql)
    migrations.add(model: Access.self, database: DatabaseIdentifier<Access.Database>.mysql)
    migrations.add(model: VideoSerie.self, database: DatabaseIdentifier<VideoSerie.Database>.mysql)
    migrations.add(model: VideoSerieYoutubeVideo.self, database: .mysql)
    migrations.add(migration: AddVideoSeriesDeleteCascadingForeignKeysMigration.self, database: .mysql)
    migrations.add(migration: AddLasiseInSecondsToCarStageMigration.self, database: .mysql)
    migrations.add(migration: AddIsAdminToUserMigration.self, database: .mysql)
    migrations.add(migration: AddIsDraftToModelsMigration.self, database: .mysql)
    services.register(migrations)


    // Commands
    var commandConfig = CommandConfig.default()
    commandConfig.use(UpdateYoutubeVideosCommand(), as: "updateYoutubeVideos")
    commandConfig.use(ResetFromFileCommand(), as: "resetFromFile")
    services.register(commandConfig)

}
