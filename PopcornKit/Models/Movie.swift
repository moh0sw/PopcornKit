

import Foundation
import ObjectMapper

public struct Movie: Media, Equatable {

    public var id: String!
    public var slug: String! {get {return "\(title.slugged)-\(year)"} set {}}
    public var title: String!
    public var year: String!
    public var rating: Float!
    public var runtime: String!
    public var genres: [String]!
    public var summary: String!
    public var trailer: String?
    public var trailerCode: String? {
        return trailer?.sliceFrom("?v=", to: "")
    }
    public var certification: String!
    
    public var smallBackgroundImage: String? {
        return largeBackgroundImage?.replacingOccurrences(of: "original", with: "thumb")
    }
    public var mediumBackgroundImage: String? {
        return largeBackgroundImage?.replacingOccurrences(of: "original", with: "medium")
    }
    public var largeBackgroundImage: String?
    public var smallCoverImage: String? {
        return largeCoverImage?.replacingOccurrences(of: "original", with: "thumb")
    }
    public var mediumCoverImage: String? {
        return largeCoverImage?.replacingOccurrences(of: "original", with: "medium")
    }
    public var largeCoverImage: String?

    public var crew = [Crew]()
    public var actors = [Actor]()
    public var torrents = [Torrent]()
    public var currentTorrent: Torrent!
    public var subtitles: [Subtitle]?
    public var currentSubtitle: Subtitle?

    public init?(map: Map) {
        guard (map["ids.imdb"].currentValue != nil || map["imdb_id"].currentValue != nil) && map["title"].currentValue != nil && map["year"].currentValue != nil && (map["rating"].currentValue != nil || map["rating.percentage"].currentValue != nil) && map["runtime"].currentValue != nil && map["certification"].currentValue != nil && map["genres"].currentValue != nil && (map["overview"].currentValue != nil || map["synopsis"].currentValue != nil) else {return nil}
    }

    public mutating func mapping(map: Map) {
        if map.context is TraktContext {
            self.id <- map["ids.imdb"]
            self.year <- (map["year"], TransformOf<String, Int>(fromJSON: { String($0!) }, toJSON: { Int($0!)}))
            self.rating <- map["rating"]
            self.summary <- map["overview"]
            self.largeCoverImage <- map["images.poster.full"]
            self.largeBackgroundImage <- map["images.fanart.full"]
            self.runtime <- (map["runtime"], TransformOf<String, Int>(fromJSON: { String($0!) }, toJSON: { Int($0!)}))
        } else {
            self.id <- map["imdb_id"]
            self.year <- map["year"]
            self.rating <- map["rating.percentage"]
            self.summary <- map["synopsis"]
            self.largeCoverImage <- map["images.poster"]
            self.largeBackgroundImage <- map["images.fanart"]
            self.runtime <- map["runtime"]
        }
        self.title <- map["title"]
        self.trailer <- map["trailer"]
        self.certification <- map["certification"]
        self.genres <- map["genres"]
        if let torrents = map["torrents.en"].currentValue as? [String: [String: Any]] {
            for (quality, torrent) in torrents {
                if var torrent = Mapper<Torrent>().map(JSONObject: torrent) , quality != "0" {
                    torrent.quality = quality
                    self.torrents.append(torrent)
                }
            }
        }
        torrents.sort(by: <)
    }
}

public func ==(lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
}
