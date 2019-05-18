//
//  CarStageYoutubeVideo.swift
//  App
//
//  Created by Christoph Pageler on 16.08.18.
//


import Vapor
import FluentMySQL


final class CarStageYoutubeVideo: MySQLPivot {

    typealias Left = YoutubeVideo
    typealias Right = CarStage

    static var leftIDKey: LeftIDKey = \.youtubeVideoID
    static var rightIDKey: RightIDKey = \.carStageID

    var id: Int?
    var youtubeVideoID: Int
    var carStageID: Int
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         youtubeVideoID: Int,
         carStageID: Int) {
        self.id = id
        self.youtubeVideoID = youtubeVideoID
        self.carStageID = carStageID
        self.createdAt = Date()
        self.updatedAt = nil
    }

}


extension CarStageYoutubeVideo: MySQLMigration { }

struct CarStageYoutubeVideoContent: Content {

    let id: Int?
    var youtubeVideoID: Int
    var carStageID: Int
    var createdAt: Date?
    var updatedAt: Date?

}
