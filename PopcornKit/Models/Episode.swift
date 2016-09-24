

import Foundation
import ObjectMapper

public struct Episode: Media, Equatable {
    
    public var firstAirDate: Date!
    public var title: String!
    public var summary: String?
    public var id: String!
    public var slug: String! {get {return title.slugged} set {}}
    public var season: Int!
    public var episode: Int!
    public var show: Show!
    
    public var smallBackgroundImage: String? {
        return largeBackgroundImage?.replacingOccurrences(of: "original", with: "thumb")
    }
    public var mediumBackgroundImage: String? {
        return largeBackgroundImage?.replacingOccurrences(of: "original", with: "medium")
    }
    public var largeBackgroundImage: String?
    
    public var torrents = [Torrent]()
    public var currentTorrent: Torrent?
    public var subtitles = [Subtitle]()
    public var currentSubtitle: Subtitle?
    
    public init?(map: Map) {
        guard map["first_aired"].currentValue != nil && map["episode"].currentValue != nil && map["season"].currentValue != nil && map["tvdb_id"].currentValue != nil && map["torrents"].currentValue != nil else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.firstAirDate <- (map["first_aired"], DateTransform())
        self.summary <- map["overview"]
        self.episode <- map["episode"]
        self.season <- map["season"]
        self.title <- map["title"]; title = title ?? "Episode \(episode)"
        self.id <- (map["tvdb_id"], TransformOf<String, Int>(fromJSON: { String($0!) }, toJSON: { Int($0!)})); id = id.replacingOccurrences(of: "-", with: "")
        if let torrents = map["torrents"].currentValue as? [String: [String: Any]] {
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

public func ==(lhs: Episode, rhs: Episode) -> Bool {
    return lhs.id == rhs.id
}
