//
//  DeviceController.swift
//  App
//
//  Created by Christoph Pageler on 14.08.18.
//


import Vapor


final class DeviceController {

    func index(_ req: Request) throws -> Future<[Device]> {
        return Device.query(on: req).all()
    }

    func show(_ req: Request) throws -> Future<Device> {
        let pushToken = try req.parameters.next(String.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }
    }

    func create(_ req: Request) throws -> Future<Device> {
        return try req.content.decode(Device.self).flatMap { device in
            device.isTestDevice = false
            return device.save(on: req).map { device -> (Device) in
                return device
            }.flatMap { device in
                return device.updateOneSignal(db: req, eventLoop: req.eventLoop)
            }
        }
    }

    func patch(_ req: Request) throws -> Future<Device> {
        let pushToken = try req.parameters.next(String.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap({ (device) -> EventLoopFuture<Device> in
            return try req.content.decode(Device.self).flatMap { patchDevice in
                device.platform = patchDevice.platform
                device.pushToken = patchDevice.pushToken
                device.languageCode = patchDevice.languageCode
                device.updatedAt = Date()

                return device.save(on: req).flatMap { device in
                    return device.updateOneSignal(db: req, eventLoop: req.eventLoop)
                }
            }
        })
    }

    struct SetTestDeviceContent: Content {

        let bool: Bool

    }

    func setTestDevice(_ req: Request) throws -> Future<Device> {
        let pushToken = try req.parameters.next(String.self)

        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap({ (device) -> EventLoopFuture<Device> in
            return try req.content.decode(SetTestDeviceContent.self).flatMap { content in
                device.isTestDevice = content.bool
                device.updatedAt = Date()
                
                return device.save(on: req).flatMap { device in
                    return device.updateOneSignal(db: req, eventLoop: req.eventLoop)
                }
            }
        })
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let pushToken = try req.parameters.next(String.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap { device in
            return device.removeFromOneSignal(eventLoop: req.eventLoop)
        }.flatMap { device in
            return device.delete(on: req)
        }.transform(to: .ok)
    }

    func ping(_ req: Request) throws -> Future<HTTPStatus> {
        let pushToken = try req.parameters.next(String.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap(to: Void.self) { device -> EventLoopFuture<Void> in
            return device.pingOneSignal(eventLoop: req.eventLoop)
        }.transform(to: .ok)
    }

    func notificationPreferences(_ req: Request) throws -> Future<[NotificationPreference]> {
        let pushToken = try req.parameters.next(String.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap(to: [NotificationPreference].self) { device in
            return try device.notificationPreferences.query(on: req).all()
        }
    }

    func createNotificationPreference(_ req: Request) throws -> Future<NotificationPreference> {
        let pushToken = try req.parameters.next(String.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap(to: NotificationPreference.self) { device in
            guard let deviceID = device.id else {
                throw Abort(.internalServerError)
            }
            return try req.content.decode(EntityPair.self).flatMap { entityPair in
                let notificationPreference = NotificationPreference(entityType: entityPair.entityType,
                                                                    entityID: entityPair.entityID,
                                                                    deviceID: deviceID)
                return notificationPreference.save(on: req)
            }
        }
    }

    func deleteNotificationPreference(_ req: Request) throws -> Future<HTTPStatus> {
        let pushToken = try req.parameters.next(String.self)
        let notificationPreferenceId = try req.parameters.next(Int.self)
        return Device.query(on: req).filter(\Device.pushToken, .equal, pushToken).first().map(to: Device.self) { possibleDevice in
            guard let device = possibleDevice else {
                throw Abort(.notFound)
            }
            return device
        }.flatMap(to: Void.self) { device in
            guard let deviceID = device.id else {
                throw Abort(.internalServerError)
            }
            let notificationPreference = NotificationPreference.query(on: req)
                .filter(\NotificationPreference.id, .equal, notificationPreferenceId)
                .filter(\NotificationPreference.deviceID, .equal, deviceID)
                .first()
            return notificationPreference.flatMap { notificationPreference in
                guard let notificationPreference = notificationPreference else {
                    throw Abort(.internalServerError)
                }
                return notificationPreference.delete(on: req)
            }
        }.transform(to: .ok)
    }

}
