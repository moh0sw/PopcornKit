

import Foundation
import ObjectMapper

public class MovieManager: NetworkManager {
    
    /// Creates new instance of MovieManager class
    public static let sharedManager = MovieManager()
    
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
        case Trending = "trending"
        case Popularity = "seeds"
        case Rating = "rating"
        case Date = "last added"
        case Year = "year"
        case Alphabet = "title"
        
        static let arrayValue = [Trending, Popularity, Rating, Date, Year, Alphabet]
        
        func stringValue() -> String {
            switch self {
            case .Popularity:
                return "Popular"
            case .Year:
                return "Year"
            case .Date:
                return "Release Date"
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
     Load Movies from API.
     
     - Parameter page:       The page number to load.
     - Parameter limit:      The number of movies to be recieved.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return movies that match the provided genre.
     - Parameter searchTerm: Only return movies that match the provided string.
     - Parameter orderBy:    Ascending or descending.
     
     - Parameter completion: Completion handler for the request. Returns array of movies upon success, error upon failure.
     */
    public func load(
        page: Int,
        filterBy filter: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        orderBy order: orders = .Descending,
        completion: (movies: [Movie]?, error: NSError?) -> Void) {
        var params: [String: AnyObject] = ["sort": filter.rawValue, "order": order.rawValue, "genre": genre.rawValue.stringByReplacingOccurrencesOfString(" ", withString: "-").lowercaseString]
        if let searchTerm = searchTerm where !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(.GET, Popcorn.Base + Popcorn.Movies + "/\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {
                completion(movies: nil, error: response.result.error)
                return
            }
            completion(movies: Mapper<Movie>().mapArray(value), error: nil)
        }
    }
    
    /**
     Get more movie information.
     
     - Parameter imbdId: The imbd identification code for the movie.
     
     - Parameter completion:    Completion handler for the request. Returns movie upon success, error upon failure.
     */
    public func getInfo(imdbId: String, completion: (movie: Movie?, error: NSError?) -> Void) {
        self.manager.request(.GET, Popcorn.Base + Popcorn.Movie + "/\(imdbId)").validate().responseJSON { response in
            guard let value = response.result.value else {completion(movie: nil, error: response.result.error); return}
            completion(movie: Mapper<Movie>().map(value), error: nil)
        }
    }
    
}
