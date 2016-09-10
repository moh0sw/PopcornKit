

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
    public var episodes: [Episode]!
    
    public init?(_ map: Map) {
        guard map["imdb_id"].currentValue != nil && map["title"].currentValue != nil && map["year"].currentValue != nil && map["slug"].currentValue != nil && map["num_seasons"].currentValue != nil && map["rating.percentage"].currentValue != nil else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.id <- map["imdb_id"]
        self.title <- map["title"]
        self.year <- map["year"]
        self.slug <- map["slug"]
        self.status <- map["status"]
        self.numberOfSeasons <- map["num_seasons"]
        self.rating <- map["rating.percentage"]
        self.runtime <- map["runtime"]
        self.genres <- map["genres"]
        self.summary <- map["synopsis"]
        self.largeCoverImage <- map["images.poster"]
        self.largeBackgroundImage <- map["images.fanart"]
        self.episodes <- map["episodes"]
        episodes.sortInPlace({ $0.episode < $1.episode })
    }
}

public func == (lhs: Show, rhs: Show) -> Bool {
    return lhs.id == rhs.id
}
