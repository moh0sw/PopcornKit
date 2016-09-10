import Foundation
import ObjectMapper

public struct Episode: Media, Mappable, Equatable {
    
    public var firstAirDate: NSDate!
    public var title: String!
    public var summary: String!
    public var id: String!
    public var slug: String! {get {return title.slugged} set {}}
    public var season: Int!
    public var episode: Int!
    
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
    
    public var torrents: [Torrent]!
    public var currentTorrent: Torrent!
    public var subtitles: [Subtitle]?
    public var currentSubtitle: Subtitle?
    
    public init(_ map: Map) {
        
    }
    
    public mutating func mapping(map: Map) {
        self.firstAirDate <- (map["first_aired"], DateTransform())
        self.summary <- map["overview"]
        self.title <- map["title"]
        self.episode <- map["episode"]
        self.season <- map["season"]
        self.id <- (map["tvdb_id"], TransformOf<String, Int>(fromJSON: { String($0!) }, toJSON: { Int($0!)}))
        self.torrents <- map["torrents"]
    }
    
}

public func == (lhs: Episode, rhs: Episode) -> Bool {
    return lhs.season == rhs.season && lhs.episode == rhs.episode
}
