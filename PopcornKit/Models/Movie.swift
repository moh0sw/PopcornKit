

import Foundation
import ObjectMapper

/**
 Struct for managing Movie objects.
 
 **Important:** In the description of all the optional variables where it says another method must be called on **only** `MovieManager` to populate x, does not apply if the movie was loaded from Trakt. **However**, no torrent metadata will be retrieved when movies are loaded from Trakt. They will need to be retrieved by calling `getInfo:imdbId:completion` on `MovieManager`.
 
 `TraktManager` has to be called regardless to fill up the special variables.
 */
public struct Movie: Media, Equatable {
    
    /// Imdb id of the movie.
    public let id: String
    
    /// TMDB id of the movie. If movie is loaded from Trakt, this will not be `nil`. Otherwise it will be `nil` and `getTMDBId:forImdbId:completion:` will have to be called on `TraktManager`.
    public var tmdbId: Int?
    
    /// The slug of the movie. May be wrong as it is being computed from title and year instead of being pulled from apis.
    public let slug: String
    
    /// Title of the movie.
    public let title: String
    
    /// Release date of the movie.
    public let year: String
    
    /// Rating percentage for the movie.
    public let rating: Float
    
    /// The runtime of the movie rounded to the nearest minute.
    public let runtime: String
    
    /// The summary of the movie. Will default to "No summary available." if a summary is not provided by the api.
    public let summary: String
    
    /// The trailer url of the movie. Will be `nil` if a trailer is not provided by the api.
    public var trailer: String?
    
    /// The youtube code (part of the url after `?v=`) of the trailer. Will be `nil` if trailer url is `nil`.
    public var trailerCode: String? {
        return trailer?.slice(from: "?v=", to: "")
    }
    
    /// The certification type according to the Motion picture rating system.
    public let certification: String
    
    
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
    

    /// All the people that worked on the movie. Empty by default. Must be filled by calling `getPeople:forMediaOfType:id:completion` on `TraktManager`.
    public var crew = [Crew]()
    
    /// All the actors in the movie. Empty by default. Must be filled by calling `getPeople:forMediaOfType:id:completion` on `TraktManager`.
    public var actors = [Actor]()
    
    /// The related movies. Empty by default. Must be filled by calling `getRelated:media:completion` on `TraktManager`.
    public var related = [Movie]()
    
    /// The torrents for the movie. Will be empty by default if the movies were loaded from Trakt. Can be filled by calling `getInfo:imdbId:completion` on `MovieManager`.
    public var torrents: [Torrent]! = [Torrent]()
    
    /// The current torrent that the user has selected. Will be `nil` until the user selects a torrent but it is in the interest of good UX to automatically select a torrent for the user.
    public var currentTorrent: Torrent?
    
    /// The subtitles associated with the movie. Empty by default. Must be filled by calling `search:episode:imdbId:limit:completion:` on `SubtitlesManager`.
    public var subtitles: [Subtitle]! = [Subtitle]()
    
    /// The current subtitle that the user has selected. Will be `nil` until the user selects a subtitle.
    public var currentSubtitle: Subtitle?
    
    /// The genres associated with the movie.
    public var genres = [String]()
    
    public init?(map: Map) {
        do { self = try Movie(map) }
        catch { return nil }
    }

    private init(_ map: Map) throws {
        if map.context is TraktContext {
            self.id = try map.value("ids.imdb")
            self.year = try map.value("year", using: StringTransform())
            self.rating = try map.value("rating")
            self.summary = ((try? map.value("overview")) ?? "No summary available.").cleaned
            self.runtime = try map.value("runtime", using: StringTransform())
        } else {
            self.id = try map.value("imdb_id")
            self.year = try map.value("year")
            self.rating = try map.value("rating.percentage")
            self.summary = ((try? map.value("synopsis")) ?? "No summary available.").cleaned
            self.largeCoverImage = try? map.value("images.poster"); largeCoverImage = largeCoverImage?.replacingOccurrences(of: "w500", with: "w1000").replacingOccurrences(of: "SX300", with: "SX1000")
            self.largeBackgroundImage = try? map.value("images.fanart"); largeBackgroundImage = largeBackgroundImage?.replacingOccurrences(of: "w500", with: "w1920").replacingOccurrences(of: "SX300", with: "SX1920")
            self.runtime = try map.value("runtime")

        }
        let title: String = try map.value("title")
        self.title = title.cleaned
        self.tmdbId = try? map.value("ids.tmdb")
        self.slug = title.slugged
        self.trailer = try? map.value("trailer"); trailer == "false" ? trailer = nil : ()
        self.certification = try map.value("certification")
        self.genres = (try? map.value("genres")) ?? [String]()
        if let torrents = map["torrents.en"].currentValue as? [String: [String: Any]] {
            for (quality, torrent) in torrents {
                if var torrent = Mapper<Torrent>().map(JSONObject: torrent) , quality != "0" {
                    torrent.quality = quality
                    self.torrents.append(torrent)
                }
            }
        }
        torrents.sort(by: <)
    }

    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let movie =  Movie(map: map) {
                self = movie
            }
        case .toJSON:
            id >>> map["imdb_id"]
            tmdbId >>> map["ids.tmdb"]
            year >>> map["year"]
            rating >>> map["rating.percentage"]
            summary >>> map["synopsis"]
            largeCoverImage >>> map["images.poster"]
            largeBackgroundImage >>> map["images.fanart"]
            runtime >>> map["runtime"]
            title >>> map["title"]
            trailer >>> map["trailer"]
            certification >>> map["certification"]
            genres >>> map["genres"]
        }
    }
}

public func ==(lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
}
