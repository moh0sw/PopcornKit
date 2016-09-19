import Foundation
import Alamofire

public struct Trakt {
    static let apiKey = "a3b34d7ce9a7f8c1bb216eed6c92b11f125f91ee0e711207e1030e7cdc965e19"
    static let apiSecret = "22afa0081bea52793740395c6bc126d15e1f72b0bfb89bbd5729310079f1a01c"
    static let base = "https://api.trakt.tv"
    static let shows = "/shows"
    static let movies = "/movies"
    static let people = "/people"
    static let seasons = "/seasons"
    static let episodes = "/episodes"
    static let auth = "/oauth"
    static let token = "/token"
    static let sync = "/sync"
    static let playback = "/playback"
    static let history = "/history"
    static let device = "/device"
    static let code = "/code"
    static let remove = "/remove"
    static let related = "/related"
    static let watched = "/watched"
    static let scrobble = "/scrobble"
    public struct Parameters {
        static let extendedImages = ["extended" : "images"]
        static let extendedFull = ["extended" : "full"]
        static let extendedAll = ["extended" : "full,images"]
    }
    public struct Headers {
        static let Default = [
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": Trakt.apiKey
        ]
        
        static func Authorization(_ token: String) -> [String: String] {
            var Authorization = Default; Authorization["Authorization"] = "Bearer \(token)"
            return Authorization
        }
    }
    public enum MediaType: String {
        case movies = "movies"
        case shows = "shows"
        case episodes = "episodes"
        case animes = "animes"
    }
    /**
     Watched status of media.
     
     - .Watching:   When the video intially starts playing or is unpaused.
     - .Paused:     When the video is paused.
     - .Finished:   When the video is stopped or finishes playing on its own.
     */
    public enum WatchedStatus: String {
        /// When the video intially starts playing or is unpaused.
        case watching = "start"
        /// When the video is paused.
        case paused = "pause"
        /// When the video is stopped or finishes playing on its own.
        case finished = "stop"
    }
}

public struct Popcorn {
    static let base = "https://tv-v2.api-fetch.website"
    static let shows = "/shows"
    static let animes = "/animes"
    static let movies = "/movies"

    static let movie = "/movie"
    static let anime = "/anime"
    static let show = "/show"
}

open class NetworkManager: NSObject {
    internal let manager: SessionManager = {
        var configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.urlCache = nil
        configuration.requestCachePolicy = .useProtocolCachePolicy
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    /// Possible orders used in API call.
    public enum Orders: Int {
        case ascending = 1
        case descending = -1
        
    }
}
