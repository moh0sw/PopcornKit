

import Foundation
import ObjectMapper

/**
 Struct for managing actor objects.
 */
public struct Actor: Person, Equatable {
    
    /// Name of the actor.
    public let name: String
    /// Name of the character the actor played in a movie.
    public let characterName: String
    /// Imdb id of the actor.
    public let imdbId: String
    /// TMDB id of the person.
    public let tmdbId: Int
    
    /// If headshot image is available, it is returned with size 1000*1500.
    public var largeImage: String?
    /// If headshot image is available, it is returned with size 600*900.
    public var mediumImage: String? {
        return largeImage?.replacingOccurrences(of: "w1920", with: "w600")
    }
    /// If headshot image is available, it is returned with size 300*450.
    public var smallImage: String? {
        return largeImage?.replacingOccurrences(of: "w1920", with: "w300")
    }
    

    public init?(map: Map) {
        do { self = try Actor(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws {
        self.name = try map.value("person.name")
        self.characterName = try map.value("character")
        self.largeImage = try? map.value("person.images.headshot.full")
        self.imdbId = try map.value("person.ids.imdb")
        self.tmdbId = try map.value("person.ids.tmdb")
    }

    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let actor = Actor(map: map) {
                self = actor
            }
        case .toJSON:
            name >>> map["person.name"]
            characterName >>> map["character"]
            largeImage >>> map["person.images.headshot.full"]
            imdbId >>> map["person.ids.imdb"]
            tmdbId >>> map["person.ids.tmdb"]
        }
    }
}

public func ==(rhs: Actor, lhs: Actor) -> Bool {
    return rhs.imdbId == lhs.imdbId
}
