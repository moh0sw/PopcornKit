import Foundation
import Alamofire

public struct Trakt {
    static let APIKey = "a3b34d7ce9a7f8c1bb216eed6c92b11f125f91ee0e711207e1030e7cdc965e19"
    static let APISecret = "22afa0081bea52793740395c6bc126d15e1f72b0bfb89bbd5729310079f1a01c"
    static let Base = "https://api.trakt.tv"
    static let Shows = "/shows"
    static let Movies = "/movies"
    static let People = "/people"
    static let Seasons = "/seasons"
    static let Episodes = "/episodes"
    static let Auth = "/oauth"
    static let Token = "/token"
    static let Sync = "/sync"
    static let Playback = "/playback"
    static let History = "/history"
    static let Remove = "/remove"
    static let Related = "/related"
    static let Watched = "/watched"
    static let Scrobble = "/scrobble"
    public struct Parameters {
        static let ExtendedImages = ["extended" : "images"]
        static let ExtendedFull = ["extended" : "full"]
        static let ExtendedAll = ["extended" : "full,images"]
    }
    public struct Headers {
        static let Default = [
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": Trakt.APIKey
        ]
        
        static func Authorization(token: String) -> [String: String] {
            var Authorization = Default; Authorization["Authorization"] = "Bearer \(token)"
            return Authorization
        }
    }
    public enum MediaType: String {
        case Movies = "movies"
        case Shows = "shows"
        case Episodes = "episodes"
        case Animes = "animes"
    }
    /**
     Watched status of media.
     
     - .Watching:   When the video intially starts playing or is unpaused.
     - .Paused:     When the video is paused.
     - .Finished:   When the video is stopped or finishes playing on its own.
     */
    public enum WatchedStatus: String {
        /// When the video intially starts playing or is unpaused.
        case Watching = "start"
        /// When the video is paused.
        case Paused = "pause"
        /// When the video is stopped or finishes playing on its own.
        case Finished = "stop"
    }
}

public struct Popcorn {
    static let Base = "https://tv-v2.api-fetch.website"
    static let Shows = "/shows"
    static let Animes = "/animes"
    static let Movies = "/movies"

    static let Movie = "/movie"
    static let Anime = "/anime"
    static let Show = "/show"
}



public class NetworkManager {
    internal let manager: Manager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPCookieAcceptPolicy = .Always
        configuration.HTTPShouldSetCookies = true
        configuration.URLCache = nil
        configuration.requestCachePolicy = .UseProtocolCachePolicy
        return Alamofire.Manager(configuration: configuration)
    }()
    
    /// Possible orders used in API call.
    public enum orders: Int {
        case Ascending = 1
        case Descending = -1
        
    }
}
