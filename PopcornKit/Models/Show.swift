

import Foundation
import ObjectMapper

public struct Show: Media, Equatable {
    
    public var id: String!
    public var slug: String!
    public var title: String!
    public var year: String!
    public var rating: Float!
    public var runtime: String!
    public var genres: [String]!
    public var summary: String!
    public var status: String!
    public var numberOfSeasons: Int!
    
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
    
    public var directors: [Crew] {return crew.filter({$0.roleType == .Director})}
    public var crew = [Crew]()
    public var actors = [Actor]()
    public var episodes = [Episode]()
    
    public init?(map: Map) {
        guard (map["imdb_id"].currentValue != nil || map["ids.imdb"].currentValue != nil || map["_id"].currentValue != nil) && map["title"].currentValue != nil && map["year"].currentValue != nil && (map["slug"].currentValue != nil || map["ids.slug"].currentValue != nil) && (map["rating"].currentValue != nil || map["rating.percentage"].currentValue != nil) else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        if map.context is TraktContext {
            self.id <- map["ids.imdb"]
            self.slug <- map["ids.slug"]
            self.year <- (map["year"], TransformOf<String, Int>(fromJSON: { String($0!) }, toJSON: { Int($0!)}))
            self.rating <- map["rating"]
            self.largeCoverImage <- map["images.poster.full"]
            self.largeBackgroundImage <- map["images.fanart.full"]
        } else {
            self.id <- map["imdb_id"]; id = id ?? map["_id"].currentValue as? String
            self.year <- map["year"]
            self.rating <- map["rating.percentage"]
            self.largeCoverImage <- map["images.poster"]
            self.largeBackgroundImage <- map["images.fanart"]
            self.slug <- map["slug"]
        }
        self.summary <- map["synopsis"]
        self.title <- map["title"]
        self.year <- map["year"]
        self.status <- map["status"]
        self.numberOfSeasons <- map["num_seasons"]
        self.runtime <- map["runtime"]
        self.genres <- map["genres"]
        self.episodes <- map["episodes"]
        self.runtime <- map["runtime"]
        self.episodes.sort(by: { $0.episode < $1.episode })
    }
}

public func == (lhs: Show, rhs: Show) -> Bool {
    return lhs.id == rhs.id
}
