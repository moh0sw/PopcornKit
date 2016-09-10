import Foundation
import Alamofire

internal struct Trakt {
    static let APIKey = "a3b34d7ce9a7f8c1bb216eed6c92b11f125f91ee0e711207e1030e7cdc965e19"
    static let Base = "https://api.trakt.tv/"
    static let Shows = "/shows/"
    static let People = "people/"
    static let Season = "/seasons/"
    static let Episodes = "/episodes/"
    static let Parameters = ["extended" : "images"]
    static let Headers = [
        "Content-Type": "application/json",
        "trakt-api-version": "2",
        "trakt-api-key": Trakt.APIKey
    ]
}

internal struct Popcorn {
    static let Base = "https://tv-v2.api-fetch.website"
    static let Shows = "/shows/"
    static let Animes = "/animes/"
    static let Movies = "/movies/"

    static let Movie = "/movie/"
    static let Anime = "/anime/"
    static let Show = "/show/"
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
    enum orders: Int {
        case Ascending = 1
        case Descending = -1
        
    }
}
