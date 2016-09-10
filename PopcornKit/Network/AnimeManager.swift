

import Foundation
import Alamofire
import ObjectMapper

class AnimeManager: NetworkManager {
    
    /// Creates new instance of AnimeManager class
    static let sharedManager = AnimeManager()
    
    /// Possible genres used in API call.
    enum genres: String {
        case All = "All"
        case Action = "Action"
        case Adventure = "Adventure"
        case Comedy = "Comedy"
        case Dementia = "Dementia"
        case Demons = "Demons"
        case Drama = "Drama"
        case Ecchi = "Ecchi"
        case Fantasy = "Fantasy"
        case Game = "Game"
        case GenderBender = "Gender Bender"
        case Gore = "Gore"
        case Harem = "Harem"
        case Historical = "Historical"
        case Horror = "Horror"
        case Kids = "Kids"
        case Magic = "Magic"
        case MahouShoujo = "Mahou Shoujo"
        case MahouShounen = "Mahou Shounen"
        case MartialArts = "Martial Arts"
        case Mecha = "Mecha"
        case Military = "Military"
        case Music = "Music"
        case Mystery = "Mystery"
        case Parody = "Parody"
        case Police = "Police"
        case Psychological = "Psychological"
        case Racing = "Racing"
        case Romance = "Romance"
        case Samurai = "Samurai"
        case School = "School"
        case SciFi = "Sci-Fi"
        case ShounenAi = "Shounen Ai"
        case ShoujoAi = "Shoujo Ai"
        case SliceOfLife = "Slice of Life"
        case Space = "Space"
        case Sports = "Sports"
        case Supernatural = "Supernatural"
        case SuperPower = "Super Power"
        case Thriller = "Thriller"
        case Vampire = "Vampire"
        case Yuri = "Yuri"
        
        static let arrayValue = [All, Action, Adventure, Comedy, Dementia, Demons, Drama, Ecchi, Fantasy, Game, GenderBender, Gore, Harem, Historical, Horror, Kids, Magic, MahouShoujo, MahouShounen, MartialArts, Mecha, Military, Music, Mystery, Parody, Police, Psychological, Racing, Romance, Samurai, School, SciFi, ShounenAi, ShoujoAi, SliceOfLife, Space, Sports, Supernatural, SuperPower, Thriller, Vampire, Yuri]
    }
    
    /// Possible filters used in API call.
    enum filters: String {
        case Popularity = "popularity"
        case Year = "year"
        case Date = "updated"
        case Rating = "rating"
        case Alphabet = "name"
        
        static let arrayValue = [Popularity, Rating, Date, Year, Alphabet]
        
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
            }
        }
    }
    
    /**
     Load Anime from API.
     
     - Parameter page:       The page number to load.
     - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
     - Paramter genre:       Only return anime that match the provided genre.
     - Parameter searchTerm: Only return animes that match the provided string.
     - Parameter order:      Ascending or descending.
     
     - Parameter completion: Completion handler for the request. Returns array of animes upon success, error upon failure.
     */
    func load(
        page: Int,
        filterBy: filters,
        genre: genres = .All,
        searchTerm: String? = nil,
        order: orders = .Descending,
        completion: ((shows: [Show]?, error: NSError?) -> Void)?) {
        var params: [String: AnyObject] = ["sort": filterBy.rawValue, "type": genre.rawValue, "order": order.rawValue]
        if let searchTerm = searchTerm  where !searchTerm.isEmpty {
            params["keywords"] = searchTerm
        }
        self.manager.request(.GET, Popcorn.Base + Popcorn.Animes + "\(page)", parameters: params).validate().responseJSON { response in
            guard let value = response.result.value else {
                completion?(shows: nil, error: response.result.error)
                print("Error is: \(response.result.error!)")
                return
            }
            completion?(shows: Mapper<Show>().mapArray(value), error: nil)
        }
    }
    
    /**
     Get more anime information.
     
     - Parameter id:            The identification code of the anime.
     
     - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
     */
    func getAnimeInfo(id: String, completion: ((show: Show?, error: NSError?) -> Void)?) {
        self.manager.request(.GET, Popcorn.Base + Popcorn.Anime + "\(id)").validate().responseJSON { response in
            guard let value = response.result.value else {
                completion?(show: nil, error: response.result.error)
                print("Error is: \(response.result.error!)")
                return
            }
            completion?(show: Mapper<Show>().map(value), error: nil)
        }
    }
}
