//
//  app.swift
//  App
//
//  Created by Christoph Pageler on 12.08.18.
//


import Vapor


public func app(_ env: Environment) throws -> Application {

    var config = Config.default()
    var env = env
    var services = Services.default()
    try configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try boot(app)
    return app
    
}
