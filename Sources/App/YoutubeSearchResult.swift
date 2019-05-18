//
//  YoutubeSearchResult.swift
//  App
//
//  Created by Christoph Pageler on 13.08.18.
//


import Foundation
import SwiftyJSON


class YoutubeSearchResult {

    let nextPageToken: String?
    let items: [YoutubeSearchResultItem]

    required init?(json: JSON) {
        nextPageToken = json["nextPageToken"].string

        var tmpItems = [YoutubeSearchResultItem]()
        if let jsonItems = json["items"].array {
            for jsonItem in jsonItems {
                if let item = YoutubeSearchResultItem(json: jsonItem) {
                    tmpItems.append(item)
                }
            }
        }
        items = tmpItems
    }

}


class YoutubeSearchResultItem {

    let id: String
    let title: String
    let description: String
    let thumbnailURL: String
    let publishedAt: Date

    static var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.'000Z'"
        return df
    }()

    required init?(json: JSON) {
        guard
            let id = json["snippet"]["resourceId"]["videoId"].string,
            let title = json["snippet"]["title"].string,
            let description = json["snippet"]["description"].string,
            let thumbnailURL = json["snippet"]["thumbnails"]["high"]["url"].string,
            let publishedAtString = json["snippet"]["publishedAt"].string,
            let publishedAtDate = YoutubeSearchResultItem.dateFormatter.date(from: publishedAtString)
        else {
            return nil
        }

        self.id = id
        self.title = title
        self.description = description.trunc(length: 255)
        self.thumbnailURL = thumbnailURL
        self.publishedAt = publishedAtDate
    }

}

extension String {
    /*
     Truncates the string to the specified length number of characters and appends an optional trailing string if longer.
     - Parameter length: Desired maximum lengths of a string
     - Parameter trailing: A 'String' that will be appended after the truncation.

     - Returns: 'String' object.
     */
    func trunc(length: Int, trailing: String = "") -> String {
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}
