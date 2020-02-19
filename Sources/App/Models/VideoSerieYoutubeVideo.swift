//
//  VideoSerieYoutubeVideo.swift
//  App
//
//  Created by Christoph Pageler on 24.10.18.
//


import Vapor
import FluentMySQL


final class VideoSerieYoutubeVideo: MySQLPivot {

    typealias Left = YoutubeVideo
    typealias Right = VideoSerie

    static var leftIDKey: LeftIDKey = \.youtubeVideoID
    static var rightIDKey: RightIDKey = \.videoSerieID

    var id: Int?
    var youtubeVideoID: Int
    var videoSerieID: Int

    var description: String?

    var isDraft: Bool
    var createdAt: Date?
    var updatedAt: Date?

    init(id: Int? = nil,
         youtubeVideoID: Int,
         videoSerieID: Int,
         isDraft: Bool) {
        self.id = id
        self.youtubeVideoID = youtubeVideoID
        self.videoSerieID = videoSerieID
        self.isDraft = isDraft
        self.createdAt = Date()
        self.updatedAt = nil
    }

}


extension VideoSerieYoutubeVideo: MySQLMigration { }

struct VideoSerieYoutubeVideoContent: Content {

    var id: Int?

    var youtubeVideoID: Int
    var videoSerieID: Int

    var description: String?

    var createdAt: Date?
    var updatedAt: Date?

}

struct VideoSerieYoutubeVideoUpdateRequest: Content {

    var description: String

}

struct VideoSerieVideoRelation: Content {

    var description: String?
    var video: YoutubeVideo

    init(description: String?, video: YoutubeVideo) {
        self.description = description
        self.video = video
    }

}
