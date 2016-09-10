

import Foundation
import ObjectMapper

public struct Movie: Media, Equatable {

    public var id: String!
    public var slug: String! {get {return title.slugged} set {}}
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
        return largeBackgroundImage?.stringByReplacingOccurrencesOfString("original", withString: "thumb")
    }
    public var mediumBackgroundImage: String? {
        return largeBackgroundImage?.stringByReplacingOccurrencesOfString("original", withString: "medium")
    }
    public var largeBackgroundImage: String?
    public var smallCoverImage: String? {
        return largeCoverImage?.stringByReplacingOccurrencesOfString("original", withString: "thumb")
    }
    public var mediumCoverImage: String? {
        return largeCoverImage?.stringByReplacingOccurrencesOfString("original", withString: "medium")
    }
    public var largeCoverImage: String?

    public var directors: [Crew] {return crew.filter({$0.roleType == .Director})}
    public var crew: [Crew]!
    public var actors: [Actor]!
    public var torrents = [Torrent]()
    public var currentTorrent: Torrent!
    public var subtitles: [Subtitle]?
    public var currentSubtitle: Subtitle?

    public init?(_ map: Map) {
        guard map["imdb_id"].currentValue != nil && map["title"].currentValue != nil && map["year"].currentValue != nil && map["rating.percentage"].currentValue != nil && map["runtime"].currentValue != nil && map["certification"].currentValue != nil && map["genres"].currentValue != nil && map["synopsis"].currentValue != nil else {return nil}
    }

    public mutating func mapping(map: Map) {
        self.id <- map["imdb_id"]
        self.title <- map["title"]
        self.year <- map["year"]
        self.rating <- map["rating.percentage"]
        self.runtime <- map["runtime"]
        self.trailer <- map["trailer"]
        self.certification <- map["certification"]
        self.genres <- map["genres"]
        self.summary <- map["synopsis"]
        self.largeCoverImage <- map["images.poster"]
        self.largeBackgroundImage <- map["images.fanart"]
        if let torrents = map["torrents.en"].currentValue as? [String: [String: AnyObject]] {
            for (quality, torrent) in torrents {
                if var torrent = Mapper<Torrent>().map(torrent) where quality != "0" {
                    torrent.quality = quality
                    self.torrents.append(torrent)
                }
            }
        }
        torrents.sortInPlace(<)
    }

}

public func ==(lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
}
