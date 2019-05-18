//
//  YoutubeVideo.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import FluentMySQL
import Vapor


final class YoutubeVideo: MySQLModel {

    var id: Int?
    var videoID: String
    var title: String
    var description: String
    var thumbnailURL: String
    var publishedAt: Date
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         videoID: String,
         title: String,
         description: String,
         thumbnailURL: String,
         publishedAt: Date) {
        self.id = id
        self.videoID = videoID
        self.title = title
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.publishedAt = publishedAt
        self.createdAt = Date()
        self.updatedAt = nil
    }

    var stages: Siblings<YoutubeVideo, CarStage, CarStageYoutubeVideo> {
        return siblings()
    }

    var videoSeries: Siblings<YoutubeVideo, VideoSerie, VideoSerieYoutubeVideo> {
        return siblings()
    }

}


extension YoutubeVideo: Migration { }


extension YoutubeVideo: Content { }


extension YoutubeVideo: Parameter { }
