

import Foundation
import ObjectMapper

/**
 Struct for managing show or anime objects. 
 
 **Important:** In the description of all the optional variables where it says another method must be called on **only** `ShowManager` or `AnimeManager`to populate x, does not apply if the show or anime was loaded from Trakt. **However** episodes array will be empty for both Trakt and popcorn-api show objects.
 
 `TraktManager` has to be called regardless to fill up the special variables.
 */
public struct Show: Media, Equatable {
    
    /// Imdb for show, arbitrary id for anime.
    public var id: String
    
    /// TMDB id of the show. This will be `nil` unless explicitly set by calling `getTMDBId:forImdbId:completion:` on `TraktManager` or the show was loaded from Trakt.
    public var tmdbId: Int?
    
    /// Tvdb for show and anime. Will **sometimes** be `nil` if shows were loaded from popcorn-api and not trakt. ie. unless user selects show from relatedShows.
    public var tvdbId: String?
    
    /// Slug for show and anime.
    public let slug: String
    
    /// Title for show and anime.
    public let title: String
    
    /// Release date of the show and anime.
    public let year: String
    
    /// Rating percentage of the show and anime.
    public let rating: Float
    
    /// Summary of the show and anime. Will default to "No summary available." until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated. **However**, there may not be a summary provided by the api.
    public let summary: String
    
    /// Network that the show is officially released on. **Anime Not Supported**. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var network: String?
    
    /// Air day of the show. **Anime Not Supported**. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var airDay: String?
    
    /// Air time of the show. **Anime Not Supported**. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var airTime: String?
    
    /// Average runtime of each episode of the show and anime rounded to the nearest minute. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var runtime: String?
    
    /// Status of the show and anime. ie. Returning series, Ended etc. Will be `nil` until `getInfo:imdbId:completion` is called on `ShowManager` and shows are updated.
    public var status: String?
    
    /// The season numbers of the available seasons. The popcorn-api only retrieves some seasons in arbitrary order. This variable contains the sorted season numbers. For example, popcorn-api only fetches series 6-8 of House. This array will contain the numbers 6,7 and 8 sorted by lowest first instead of 3,1,5,4,7,6,8,2.
    public var seasonNumbers: [Int] {
        return Array(Set(episodes.map({$0.season}))).sorted()
    }
    
    /// If fanart image is available, it is returned with size 650*366.
    public var smallBackgroundImage: String? {
        let amazonUrl = largeBackgroundImage?.isAmazonUrl ?? false
        return largeBackgroundImage?.replacingOccurrences(of: amazonUrl ? "SX1920" : "w1920", with: amazonUrl ? "SX650" : "w650")
    }
    
    /// If fanart image is available, it is returned with size 1280*720.
    public var mediumBackgroundImage: String? {
        let amazonUrl = largeBackgroundImage?.isAmazonUrl ?? false
        return largeBackgroundImage?.replacingOccurrences(of: amazonUrl ? "SX1920" : "w1920", with: amazonUrl ? "SX1280" : "w1280")
    }
    
    /// If fanart image is available, it is returned with size 1920*1080.
    public var largeBackgroundImage: String?
    
    /// If poster image is available, it is returned with size 450*300.
    public var smallCoverImage: String? {
        let amazonUrl = largeCoverImage?.isAmazonUrl ?? false
        return largeCoverImage?.replacingOccurrences(of: amazonUrl ? "SX1000" : "w1000", with: amazonUrl ? "SX300" : "w300")
    }
    
    /// If poster image is available, it is returned with size 975*650.
    public var mediumCoverImage: String? {
        let amazonUrl = largeCoverImage?.isAmazonUrl ?? false
        return largeCoverImage?.replacingOccurrences(of: amazonUrl ? "SX1000" : "w1000", with: amazonUrl ? "SX650" : "w650")
    }
    
    /// If poster image is available, it is returned with size 1500*1000
    public var largeCoverImage: String?
    
    
    /// All the people that worked on the show or anime. Empty by default. Must be filled by calling `getPeople:forMediaOfType:id:completion` on `TraktManager`.
    public var crew = [Crew]()
    
    /// All the actors in the show or anime. Empty by default. Must be filled by calling `getPeople:forMediaOfType:id:completion` on `TraktManager`.
    public var actors = [Actor]()
    
    /// The related shows or anime. Empty by default. Must be filled by calling `getRelated:media:completion` on `TraktManager`.
    public var related = [Show]()
    
    /// All the episodes in the show or anime sorted by season number. Empty by default. Must be filled by calling `getInfo:imdbId:completion` on `ShowManager or AnimeManager`.
    public var episodes = [Episode]()
    
    /// The genres associated with the show or anime. Will be empty by default on shows but will be filled by default on anime. Can be filled by calling `getInfo:imdbId:completion` on `ShowManager or AnimeManager`.
    public var genres = [String]()
    
    public init?(map: Map) {
        do { self = try Show(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws {
        if map.context is TraktContext {
            self.id = try map.value("ids.imdb")
            self.tvdbId = try? map.value("ids.tvdb", using: StringTransform())
            self.slug = try map.value("ids.slug")
            self.year = try map.value("year", using: StringTransform())
            self.airDay = try? map.value("airs.day")
            self.airTime = try? map.value("airs.time")
            self.rating = try map.value("rating")
        } else {
            self.id = try (try? map.value("imdb_id")) ?? map.value("_id")
            self.tvdbId = try? map.value("tvdb_id")
            self.year = try map.value("year")
            self.rating = try map.value("rating.percentage")
            self.largeCoverImage = try? map.value("images.poster"); largeCoverImage = largeCoverImage?.replacingOccurrences(of: "w500", with: "w1000").replacingOccurrences(of: "SX300", with: "SX1000")
            self.largeBackgroundImage = try? map.value("images.fanart"); largeBackgroundImage = largeBackgroundImage?.replacingOccurrences(of: "w500", with: "w1920").replacingOccurrences(of: "SX300", with: "SX1920")
            self.slug = try map.value("slug")
            self.airDay = try? map.value("air_day")
            self.airTime = try? map.value("air_time")
        }
        self.summary = ((try? map.value("synopsis")) ?? "No summary available.").cleaned
        let title: String = try map.value("title")
        self.title = title.cleaned
        self.status = try? map.value("status")
        self.runtime = try? map.value("runtime")
        self.genres = (try? map.value("genres")) ?? [String]()
        self.episodes = (try? map.value("episodes")) ?? [Episode]()
        self.tmdbId = try? map.value("ids.tmdb")
        self.network = try? map.value("network")
        
        var episodes = [Episode]()
        for var episode in self.episodes {
            episode.show = self
            episodes.append(episode)
        }
        self.episodes = episodes
        self.episodes.sort(by: { $0.episode < $1.episode })
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let show = Show(map: map) {
                self = show
            }
        case .toJSON:
            id >>> map["imdb_id"]
            tmdbId >>> map["ids.tmdb"]
            tvdbId >>> map["tvdb_id"]
            slug >>> map["slug"]
            year >>> map["year"]
            rating >>> map["rating.percentage"]
            largeCoverImage >>> map["images.poster"]
            largeBackgroundImage >>> map["images.fanart"]
            title >>> map["title"]
            runtime >>> map["runtime"]
            summary >>> map["synopsis"]
            genres >>> map["genres"]
            status >>> map["status"]
            airDay >>> map["air_day"]
            airTime >>> map["air_time"]
        }
    }
}

public func ==(lhs: Show, rhs: Show) -> Bool {
    return lhs.id == rhs.id
}
