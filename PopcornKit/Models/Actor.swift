

import Foundation
import ObjectMapper

public struct Actor: Person, Equatable {

    public var name: String!
    public var characterName: String!
    public var mediumImage: String?
    public var smallImage: String?
    public var largeImage: String?
    public var imdbId: String!

    public init?(_ map: Map) {
        guard map["character"].currentValue != nil && map["person.name"].currentValue != nil && map["person.ids.imdb"].currentValue != nil  else {return nil}
    }

    public mutating func mapping(map: Map) {
        self.name <- map["person.name"]
        self.characterName <- map["character"]
        self.largeImage <- map["person.images.headshot.full"]
        self.mediumImage <- map["person.images.headshot.medium"]
        self.smallImage <- map["person.images.headshot.thumb"]
        self.imdbId <- map["person.ids.imdb"]
    }
    
}

public func ==(rhs: Actor, lhs: Actor) -> Bool {
    return rhs.imdbId == lhs.imdbId
}
