

import Foundation
import ObjectMapper

/**
 Struct for managing episode objects.
 
 **Important**: All images are `nil` unless episode was loaded from trakt. An image is obtained by calling `getEpisodeMetadata:showId:episodeNumber:seasonNumber:completion:` on `TraktManager`. Once image is obtained only the `largeBackgroundImage` variable should be set; the other two are computed and are not settable - they will be automatically updated once `largeBackgroundImage` is set.
 */
public struct Episode: Media, Equatable {
    
    /// The date of which the episode was first aired. Will be `nil` for all anime episodes.
    public var firstAirDate: Date?
    
    /// The title of the episode. If there is no title, the string "Episode" followed by the episode number will be used.
    public let title: String
    
    /// The summary of the episode. Will default to "No summary available." if there is no summary available on the popcorn-api.
    public var summary: String
    
    /// The tvdb id of the episode.
    public let id: String
    
    /// TMDB id of the episode. This will be `nil` unless explicitly set by calling `getTMDBId:forImdbId:completion:` on `TraktManager` or the episode was loaded from Trakt.
    public var tmdbId: Int?
    
    /// The slug for episode. May be wrong as it is being computed from title instead of being pulled from apis.
    public let slug: String
    
    /// The season that the episode is in.
    public let season: Int
    
    /// The number of the episode in relation to the season.
    public let episode: Int
    
    /// The corresponding show object.
    public var show: Show!
    
    
    /// If fanart image is available, it is returned with size 600*338. Will be `nil` until an image is obtained by calling `getEpisodeMetadata:showId:episodeNumber:seasonNumber:completion:` on `TraktManager`.
    public var smallBackgroundImage: String? {
        return largeBackgroundImage?.replacingOccurrences(of: "w1920", with: "w600")
    }
    
    /// If fanart image is available, it is returned with size 1000*536. Will be `nil` until an image is obtained by calling `getEpisodeMetadata:showId:episodeNumber:seasonNumber:completion:` on `TraktManager`.
    public var mediumBackgroundImage: String? {
        return largeBackgroundImage?.replacingOccurrences(of: "w1920", with: "w1000")
    }
    
    /// If fanart image is available, it is returned with size 1920*1080. Will be `nil` until an image is obtained by calling `getEpisodeMetadata:showId:episodeNumber:seasonNumber:completion:` on `TraktManager`.
    public var largeBackgroundImage: String?
    
    
    /// The torrents for the episode. May be empty if no torrents are available or if episode was loaded from Trakt. Can be obtained by calling `getInfo:imdbId:completion` on `ShowManager or AnimeManager`. Keep in mind the aformentioned method does not return images so `getEpisodeMetadata:showId:episodeNumber:seasonNumber:completion:` will have to be called on `TraktManager`.
    public var torrents: [Torrent]! = [Torrent]()
    
    /// The current torrent that the user has selected. Will be `nil` until the user selects a torrent but it is in the interest of good UX to automatically select a torrent for the user.
    public var currentTorrent: Torrent?
    
    /// The subtitles associated with the episode. Empty by default. Must be filled by calling `search:episode:imdbId:limit:completion:` on `SubtitlesManager`.
    public var subtitles: [Subtitle]! = [Subtitle]()
    
    /// The current subtitle that the user has selected. Will be `nil` until the user selects a subtitle.
    public var currentSubtitle: Subtitle?
    
    public init?(map: Map) {
        do { self = try Episode(map) }
        catch { return nil }
    }
    
    private init(_ map: Map) throws {
        if map.context is TraktContext {
            self.id = try map.value("ids.tvdb", using: StringTransform())
            self.episode = try map.value("number")
        } else {
            self.episode = try map.value("episode")
            self.id = try map.value("tvdb_id", using: StringTransform()).replacingOccurrences(of: "-", with: "")
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
        self.tmdbId = try? map.value("ids.tmdb")
        self.show = try? map.value("show") // Will only not be `nil` if object is mapped from JSON array, otherwise this is set in `Show` struct.
        self.firstAirDate =  try map.value("first_aired", using: DateTransform())
        self.summary = ((try? map.value("overview")) ?? "No summary available.").cleaned
        self.season = try map.value("season")
        let episode = self.episode // Stop compiler complaining about passing uninitialised variables to closure.
        self.title = ((try? map.value("title")) ?? "Episode \(episode)").cleaned
        self.slug = title.slugged
        self.largeBackgroundImage = try? map.value("images.fanart")
    }
    
    public mutating func mapping(map: Map) {
        switch map.mappingType {
        case .fromJSON:
            if let episode = Episode(map: map) {
                self = episode
            }
        case .toJSON:
            id >>> (map["tvdb_id"], StringTransform())
            tmdbId >>> map["ids.tmdb"]
            firstAirDate >>> (map["first_aired"], DateTransform())
            summary >>> map["overview"]
            season >>> map["season"]
            show >>> map["show"]
            episode >>> map["episode"]
            largeBackgroundImage >>> map["images.fanart"]
            title >>> map["title"]
        }
    }
}

public func ==(lhs: Episode, rhs: Episode) -> Bool {
    return lhs.id == rhs.id
}
