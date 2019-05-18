//
//  NotificationPreference.swift
//  App
//
//  Created by Christoph Pageler on 14.08.18.
//


import FluentMySQL
import Vapor


final class NotificationPreference: MySQLModel {

    var id: Int?
    var entityType: String
    var entityID: String?
    var deviceID: Device.ID
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         entityType: String,
         entityID: String?,
         deviceID: Device.ID) {
        self.id = id
        self.entityType = entityType
        self.entityID = entityID
        self.deviceID = deviceID
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var device: Parent<NotificationPreference, Device> {
        return parent(\.deviceID)
    }

    static func devicesMatchingWith(entityPair: EntityPair, db: DatabaseConnectable) -> Future<[Device]> {
        var query = NotificationPreference.query(on: db).filter(\.entityType, .equal, entityPair.entityType)

        if let filterID = entityPair.entityID {
            query = query.group(.or) { query in
                query.filter(\.entityID, .equal, filterID).filter(\.entityID, .equal, nil)
            }
        }

        return query.join(\Device.id, to: \NotificationPreference.deviceID)
            .alsoDecode(Device.self)
            .all()
            .map(to: [Device].self)
        { join in
            var devices: [Device] = []
            for (_, device) in join {
                if !devices.contains(where: { $0.id == device.id }) {
                    devices.append(device)
                }
            }
            return devices.filter({ $0.externalID != nil })
        }
    }

}


extension NotificationPreference: Migration { }


extension NotificationPreference: Content { }


extension NotificationPreference: Parameter { }


struct EntityPair: Content {

    var entityType: String
    var entityID: String?

}
