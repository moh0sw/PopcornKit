

import Foundation
import ObjectMapper

public struct Crew: Person, Equatable {

    public var name: String!
    public var job: String!
    public var roleType: Role!
    public var mediumImage: String?
    public var smallImage: String?
    public var largeImage: String?
    public var imdbId: String!
    
    public init?(_ map: Map) {
        guard map["job"].currentValue != nil && map["person.name"].currentValue != nil && map["person.ids.imdb"].currentValue != nil  else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.name <- map["person.name"]
        self.job <- map["job"]
        self.largeImage <- map["person.images.headshot.full"]
        self.mediumImage <- map["person.images.headshot.medium"]
        self.smallImage <- map["person.images.headshot.thumb"]
        self.imdbId <- map["person.ids.imdb"]
    }

}

public func ==(rhs: Crew, lhs: Crew) -> Bool {
    return rhs.imdbId == lhs.imdbId
}

public enum Role: String {
    case Artist = "art"
    case CameraMan = "camera"
    case Designer = "costume & make-up"
    case Director = "directing"
    case Other = "crew"
    case Producer = "production"
    case SoundEngineer = "sound"
    case Writer = "writing"
}
