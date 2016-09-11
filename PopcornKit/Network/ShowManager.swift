

import Foundation
import ObjectMapper

public class ShowManager: NetworkManager {
    
    /// Creates new instance of ShowManager class
    public static let sharedManager = ShowManager()
    
    /// Possible genres used in API call.
    public enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Animation = "Animation"
        case Comedy = "Comedy"
        case Crime = "Crime"
        case Disaster = "Disaster"
        case Documentary = "Documentary"
        case Drama = "Drama"
        case Family = "Family"
        case FanFilm = "Fan Film"
        case Fantasy = "Fantasy"
        case FilmNoir = "Film Noir"
        case History = "History"
        case Holiday = "Holiday"
        case Horror = "Horror"
        case Indie = "Indie"
        case Music = "Music"
        case Mystery = "Mystery"
        case Road = "Road"
        case Romance = "Romance"
        case SciFi = "Science Fiction"
        case Short = "Short"
        case Sport = "Sports"
        case SportingEvent = "Sporting Event"
        case Suspense = "Suspense"
        case Thriller = "Thriller"
        case War = "War"
        case Western = "Western"
        
        static let arrayValue = [All, Action, Adventure, Animation, Comedy, Crime, Disaster, Documentary, Drama, Family, FanFilm, Fantasy, FilmNoir, History, Holiday, Horror, Indie, Music, Mystery, Road, Romance, SciFi, Short, Sport, SportingEvent, Suspense, Thriller, War, Western]
    }
    
    /// Possible filters used in API call.
    public enum filters: String {
        case Popularity = "popularity"
        case Year = "year"
        case Date = "updated"
        case Rating = "rating"
        case Alphabet = "name"
        case Trending = "trending"
        
        static let arrayValue = [Trending, Popularity, Rating, Date, Year, Alphabet]
        
        func stringValue() -> String {
            switch self {
            case .Popularity:
                return "Popular"
            case .Year:
                return "Year"
            case .Date:
                return "Last Updated"
            case .Rating:
                return "Top Rated"
            case .Alphabet:
                return "A-Z"
            case .Trending:
                return "Trending"
            }
        }
    }
    
    /**
     Load TV Shows from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return shows that match the provided genre.
     - Parameter searchTerm: Only return shows that match the provided string.
     - Parameter orderBy:    Ascending or descending.
     
     - Parameter completion: Completion handler for the request. Returns array of shows upon success, error upon failure.
     */
    public func load(
        page: Int,
        filterBy filter: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        orderBy order: orders = .Descending,
        completion: (shows: [Show]?, error: NSError?) -> Void) {
        var params: [String: AnyObject] = ["sort": filter.rawValue, "genre": genre.rawValue.stringByReplacingOccurrencesOfString(" ", withString: "-").lowercaseString, "order": order.rawValue]
        if let searchTerm = searchTerm where !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(.GET, Popcorn.Base + Popcorn.Shows + "/\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {completion(shows: nil, error: response.result.error); return}
            completion(shows: Mapper<Show>().mapArray(value), error: nil)
        }
    }
    
    /**
     Get more show information.
     
     - Parameter imbdId:        The imbd identification code of the show.
     
     - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
     */
    public func getInfo(imdbId: String, completion: (show: Show?, error: NSError?) -> Void) {
        self.manager.request(.GET, Popcorn.Base + Popcorn.Show + "/\(imdbId)").validate().responseJSON { response in
            guard let value = response.result.value else {completion(show: nil, error: response.result.error); return}
            completion(show: Mapper<Show>().map(value), error: nil)
        }
    }
}
