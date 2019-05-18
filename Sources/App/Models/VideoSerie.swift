//
//  VideoSerie.swift
//  App
//
//  Created by Christoph Pageler on 24.10.18.
//


import FluentMySQL
import Vapor


final class VideoSerie: MySQLModel {

    var id: Int?
    var title: String
    var description: String
    var isPublic: Bool
    var createdAt: Date?
    var updatedAt: Date?

    var videos: Siblings<VideoSerie, YoutubeVideo, VideoSerieYoutubeVideo> {
        return siblings()
    }

    init(id: Int? = nil,
         title: String,
         description: String,
         isPublic: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.isPublic = isPublic
        self.createdAt = Date()
        self.updatedAt = nil
    }

}


extension VideoSerie: Migration { }


extension VideoSerie: Content { }


extension VideoSerie: Parameter { }
