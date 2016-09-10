

import Foundation
import ObjectMapper

public struct Episode: Media, Equatable {
    
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
    
    public var torrents = [Torrent]()
    public var currentTorrent: Torrent!
    public var subtitles: [Subtitle]?
    public var currentSubtitle: Subtitle?
    
    public init?(_ map: Map) {
        guard map["first_aired"].currentValue != nil && map["episode"].currentValue != nil && map["season"].currentValue != nil && map["tvdb_id"].currentValue != nil && map["torrents"].currentValue != nil else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.firstAirDate <- (map["first_aired"], DateTransform())
        self.summary <- map["overview"]; summary = summary ?? "No synopsis available"
        self.episode <- map["episode"]
        self.season <- map["season"]
        self.title <- map["title"]; title = title ?? "Episode \(episode)"
        self.id <- (map["tvdb_id"], TransformOf<String, Int>(fromJSON: { String($0!) }, toJSON: { Int($0!)})); id = id.stringByReplacingOccurrencesOfString("-", withString: "")
        if let torrents = map["torrents"].currentValue as? [String: [String: AnyObject]] {
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

public func ==(lhs: Episode, rhs: Episode) -> Bool {
    return lhs.season == rhs.season && lhs.episode == rhs.episode
}
