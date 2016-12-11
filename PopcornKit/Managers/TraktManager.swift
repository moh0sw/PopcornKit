

import ObjectMapper
import Alamofire
import SwiftyJSON

#if os(iOS)
    import SafariServices
#endif

open class TraktManager: NetworkManager {
    
    
    /// Creates new instance of TraktManager class
    open static let shared = TraktManager()
    
    /// OAuth state parameter added for extra security against cross site forgery.
    fileprivate var state: String!
    
    /// The delegate for the Trakt Authentication process.
    open weak var delegate: TraktManagerDelegate?
    
    /**
     Scrobbles current video.
     
     - Parameter id:            The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter progress:      The progress of the playing video. Possible values range from 0...1.
     - Parameter type:          The type of the item, either `Episode` or `Movie`.
     - Parameter status:        The status of the item.
     
     - Parameter completion:    Optional completion handler only called if an error is thrown.
     */
    open func scrobble(_ id: String, progress: Float, type: Trakt.MediaType, status: Trakt.WatchedStatus, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else {return}
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion?(error) })
                }
            }
            var parameters = [String: Any]()
            if type == .movies {
                parameters = ["movie": ["ids": ["imdb": id]], "progress": progress * 100.0]
            } else {
                parameters = ["episode": ["ids": ["tvdb": Int(id)!]], "progress": progress * 100.0]
            }
            self.manager.request(Trakt.base + Trakt.scrobble + "/\(status.rawValue)", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error { completion?(error as NSError) }
            })
        }
    }
    
    /**
     Load episode metadata from API.
     
     - Parameter show:          The imdbId or slug for the show.
     - Parameter episodeNumber: The number of the episode in relation to its current season.
     - Parameter seasonNumber:  The season of which the episode is in.
     
     - Parameter completion:    The completion handler for the request containing an optional tvdbId, optional imdbId and an optional error.
     */
    open func getEpisodeMetadata(_ showId: String, episodeNumber: Int, seasonNumber: Int, completion: @escaping (Int?, String?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.shows +  "/\(showId)" + Trakt.seasons + "/\(seasonNumber)" + Trakt.episodes + "/\(episodeNumber)", headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion(nil, nil, response.result.error as NSError?); return }
            let responseObject = JSON(value)
            let imdbId = responseObject["ids"]["imdb"].string
            let tvdbId = responseObject["ids"]["tvdb"].int
            completion(tvdbId, imdbId, nil)
        }
    }
    
    /**
     Retrieves users previously watched videos.
     
     - Parameter forMediaOfType:    The type of the item (either movie or show).
     
     - Parameter completion:        The completion handler for the request containing an array of either imdbIds or tvdbIds depending on the type selected and an optional error.
     */
    open func getWatched(forMediaOfType type: Trakt.MediaType, completion:@escaping ([String], NSError?) -> Void) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion([String](), error) })
                }
            }
            let queue = DispatchQueue(label: "com.popcorntimetv.popcornkit.response.queue", attributes: .concurrent)
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watched + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(queue: queue, options: .allowFragments, completionHandler: { response in
                guard let value = response.result.value else { completion([String](), response.result.error as NSError?); return}
                let responseObject = JSON(value)
                var ids = [String]()
                let group = DispatchGroup()
                for (_, item) in responseObject {
                    if type == .movies, let id = item["movie"]["ids"]["imdb"].string {
                        ids.append(id)
                        continue
                    }
                    var tvdbIds = [String]()
                    guard let showImdbId = item["show"]["ids"]["imdb"].string else { continue }
                    for (_, season) in item["seasons"] {
                        guard let seasonNumber = season["number"].int else { continue }
                        for (_, episode) in season["episodes"] {
                            guard let episodeNumber = episode["number"].int else { continue }
                            group.enter()
                            self.getEpisodeMetadata(showImdbId, episodeNumber: episodeNumber, seasonNumber: seasonNumber, completion: { (tvdbId, _, _) in
                                if let tvdbId = tvdbId { tvdbIds.append(String(tvdbId)) }
                                group.leave()
                            })
                        }
                    }
                    ids += tvdbIds
                }
                group.notify(queue: .main, execute: { completion(ids, nil) })
            })
        }
    }
    
    /**
     Retrieves users playback progress of video if applicable.
     
     - Parameter forMediaOfType: The type of the item (either movie or episode).
     
     - Parameter completion: The completion handler for the request containing a dictionary of either imdbIds or tvdbIds depending on the type selected as keys and the users corrisponding watched progress as values and an optional error. Eg. ["tt1431045": 0.5] means you have watched half of Deadpool.
     */
    open func getPlaybackProgress(forMediaOfType type: Trakt.MediaType, completion: @escaping ([String: Float], NSError?) -> Void) {
        guard var credential = OAuthCredential(identifier: "trakt") else {return}
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion([String: Float](), error) })
                }
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.playback + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                guard let value = response.result.value else { completion([String: Float](), response.result.error as NSError?); return }
                let responseObject = JSON(value)
                var progressDict = [String: Float]()
                for (_, item) in responseObject {
                    var imdbId = item["movie"]["ids"]["imdb"].string
                    if let id = item["episode"]["ids"]["tvdb"].int, imdbId == nil { imdbId = String(id) }
                    if let imdbId = imdbId, let progress = item["progress"].float {
                        progressDict[imdbId] = progress/100.0
                    }
                }
                completion(progressDict, nil)
            }
        }
    }
    
    /**
     Removes a movie or episode from a users watched history.
     
     - Parameter id:                    The imdbId or tvdbId of the movie, episode or show.
     - Parameter fromWatchedlistOfType: The type of the item (movie or episode).
     
     - Parameter completion:    An optional completion handler called only if an error is thrown.
     */
    open func remove(_ id: String, fromWatchedlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else {return}
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: {completion?(error) })
                }
            }
            var parameters = [String: Any]()
            if type == .movies {
                parameters = ["movies": [["ids": ["imdb": id]]]]
            } else if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.history + Trakt.remove, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error { completion?(error as NSError) }
            })
        }
    }
    
    /**
     Retrieves cast and crew information for a movie or show.
     
     - Parameter forMediaOfType:    The type of the item (movie or show **not anime**). Anime is supported but is referenced as a show not as its own type.
     - Parameter id:                The id of the movie, show or anime.
     
     - Parameter completion:        The completion handler for the request containing an array of actors, array of crews and an optional error.
     */
    open func getPeople(forMediaOfType type: Trakt.MediaType, id: String, completion: @escaping ([Actor], [Crew], NSError?) -> Void) {
        self.manager.request(Trakt.base + "/\(type.rawValue)/\(id)" + Trakt.people, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([Actor](), [Crew](), response.result.error as NSError?); return }
            let responseObject = JSON(value)
            var actors = [Actor]()
            var crew = [Crew]()
            let group = DispatchGroup()
            for (_, actor) in responseObject["cast"] {
                guard var actor = Mapper<Actor>().map(JSONObject: actor.dictionaryObject) else { continue }
                group.enter()
                TMDBManager.shared.getCharacterHeadshots(forPersonWithImdbId: actor.imdbId, orTMDBId: actor.tmdbId, completion: { (_, image, error) in
                    if let image = image { actor.largeImage = image }
                    actors.append(actor)
                    group.leave()
                })
            }
            for (role, people) in responseObject["crew"] {
                guard let people = Mapper<Crew>().mapArray(JSONObject: people.arrayObject) else { continue }
                for var person in people {
                    group.enter()
                    TMDBManager.shared.getCharacterHeadshots(forPersonWithImdbId: person.imdbId, orTMDBId: person.tmdbId, completion: { (_, image, error) in
                        if let image = image { person.largeImage = image }
                        person.roleType = Role(rawValue: role) ?? .unknown
                        crew.append(person)
                        group.leave()
                    })
                }
            }
            group.notify(queue: .main, execute: { completion(actors, crew, nil) })
            
        }
    }
    
    /**
     Retrieves users watchlist.
     
     - Parameter forMediaOfType: The type struct of the item eg. `Movie` or `Show` or `Episode`.
     
     - Parameter completion: The completion handler for the request containing an array of media that the user has added to their watchlist and an optional error.
     */
    open func getWatchlist<T: Media>(forMediaOfType type: T.Type, completion:@escaping ([T], NSError?) -> Void) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion([T](), error) })
                }
            }
            let mediaType: String
            switch type {
            case is Movie.Type:
                mediaType = Trakt.movies
            case is Show.Type:
                mediaType = Trakt.shows
            case is Episode.Type:
                mediaType = Trakt.episodes
            default:
                mediaType = ""
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watchlist + mediaType, parameters: Trakt.extended, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
                let responseObject = JSON(value)
                var watchlist = [T]()
                let group = DispatchGroup()
                for (_, item) in responseObject {
                    guard let type = item["type"].string else { continue }
                    if let media = Mapper<T>(context: TraktContext()).map(JSONObject: item[type].dictionaryObject) {
                        guard var episode = media as? Episode, let show = Mapper<Show>(context: TraktContext()).map(JSONObject: item["show"].dictionaryObject) else {
                            group.enter()
                            let completion: (Media?, NSError?) -> Void = { (media, _) in
                                if let media = media { watchlist.append(media as! T) }
                                group.leave()
                            }
                            media is Movie ?  MovieManager.shared.getInfo(media.id, completion: completion) : ShowManager.shared.getInfo(media.id, completion: completion)
                            continue
                        }
                        episode.show = show
                        watchlist.append(episode as! T)
                    }
                }
                group.notify(queue: .main, execute: { completion(watchlist, nil) })
            }
        }
    }
    
    /**
     Adds specified media to users watchlist.
     
     - Parameter id:                The imdbId or tvdbId of the media.
     - Parameter toWatchlistOfType: The type of the item.
     
     - Parameter completion: The completion handler for the request containing an optional error if the request fails.
     */
    open func add(_ id: String, toWatchlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion?(error) })
                }
            }
            var parameters = [String: Any]()
            if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            } else {
                parameters = [type.rawValue: [["ids": ["imdb": id]]]]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watchlist, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error { completion?(error as NSError) }
            })
        }
    }
    
    /**
     Removes specified media from users watchlist.
     
     - Parameter id:                    The imdbId or tvdbId of the media.
     - Parameter fromWatchlistOfType:   The type of the item.
     
     - Parameter completion: The completion handler for the request containing an optional error if the request fails.
     */
    open func remove(_ id: String, fromWatchlistOfType type: Trakt.MediaType, completion: ((NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential(identifier: "trakt") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token, refreshToken: credential.refreshToken!, clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion?(error) })
                }
            }
            var parameters = [String: Any]()
            if type == .episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            } else {
                parameters = [type.rawValue: [["ids": ["imdb": id]]]]
            }
            self.manager.request(Trakt.base + Trakt.sync + Trakt.watchlist + Trakt.remove, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error { completion?(error as NSError) }
            })
        }
    }
    
    /**
     Retrieves related media.
     
     - Parameter media: The media you would like to get more information about. **Please note:** only the imdbdId is used but an object needs to be passed in for Swift generics to work so creating a blank object with only an imdbId variable initialised will suffice if necessary.
     
     - Parameter completion: The requests completion handler containing array of related movies and an optional error.
     */
    open func getRelated<T: Media>(_ media: T, completion: @escaping ([T], NSError?) -> Void) {
        self.manager.request(Trakt.base + (media is Movie ? Trakt.movies : Trakt.shows) + "/\(media.id)" + Trakt.related, parameters: Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
            let responseObject = JSON(value)
            let group = DispatchGroup()
            var array = [T]()
            for (_, item) in responseObject {
                guard let id = item["ids"]["imdb"].string else { continue }
                group.enter()
                let completion: (Media?, NSError?) -> Void = { (media, _) in
                    if let media = media { array.append(media as! T) }
                    group.leave()
                }
                media is Movie ?  MovieManager.shared.getInfo(id, completion: completion) : ShowManager.shared.getInfo(id, completion: completion)
            }
            group.notify(queue: .main, execute: { completion(array, nil) })
        }
    }
    
    /**
     Retrieves movies or shows that the person in cast/crew in.
     
     - Parameter forPersonWithId:   The id of the person you would like to get more information about.
     - Parameter mediaType:         Just the type of the media is required for Swift generics to work.
     
     - Parameter completion:        The requests completion handler containing array of movies and an optional error.
     */
    open func getMediaCredits<T: Media>(forPersonWithId id: String, mediaType type: T.Type, completion: @escaping ([T], NSError?) -> Void) {
        var typeString = (type is Movie.Type ? Trakt.movies : Trakt.shows)
        self.manager.request(Trakt.base + Trakt.people + "/\(id)" + typeString, parameters: Trakt.extended, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
            let responseObject = JSON(value)
            typeString.characters.removeLast() // Removes 's' from the type string
            typeString.characters.removeFirst() // Removes '/' from the type string
            var medias = [T]()
            let group = DispatchGroup()
            for (_, item) in responseObject["crew"] {
                for (_, item) in item {
                    guard let id = item[typeString]["ids"]["imdb"].string else { continue }
                    group.enter()
                    let completion: (Media?, NSError?) -> Void = { (media, _) in
                        if let media = media { medias.append(media as! T) }
                        group.leave()
                    }
                    type is Movie.Type ?  MovieManager.shared.getInfo(id, completion: completion) : ShowManager.shared.getInfo(id, completion: completion)
                }
            }
            for (_, item) in responseObject["cast"] {
                guard let id = item[typeString]["ids"]["imdb"].string else { continue }
                group.enter()
                let completion: (Media?, NSError?) -> Void = { (media, _) in
                    if let media = media { medias.append(media as! T) }
                    group.leave()
                }
                type is Movie.Type ?  MovieManager.shared.getInfo(id, completion: completion) : ShowManager.shared.getInfo(id, completion: completion)
            }
            group.notify(queue: .main, execute: { completion(medias, nil) })
        }
    }
    
    /// Downloads users latest watchlist and watchedlist from Trakt.
    open func syncUserData() {
        WatchedlistManager.movie.syncTraktProgress()
        WatchedlistManager.movie.getWatched()
        WatchlistManager<Movie>.movie.getWatchlist()
        WatchedlistManager.episode.syncTraktProgress()
        WatchedlistManager.episode.getWatched()
        WatchlistManager<Episode>.episode.getWatchlist()
        WatchedlistManager.show.syncTraktProgress()
        WatchedlistManager.show.getWatched()
        WatchlistManager<Show>.show.getWatchlist()
    }
    
    /**
     Requests tmdb id for object with imdb id.
     
     - Parameter id:            Imdb id of object.
     - Parameter completion:    Completion handler containing optional tmdb id and an optional error.
     */
    open func getTMDBId(forImdbId id: String, completion: @escaping (Int?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.search + Trakt.imdb + "/\(id)", headers: Trakt.Headers.Default).validate().responseJSON { (response) in
            guard let value = response.result.value else { completion(nil, response.result.error as NSError?); return }
            let responseObject = JSON(value).arrayValue.first
            
            if let type = responseObject?["type"].string  {
                completion(responseObject?[type]["ids"]["tmdb"].int, nil)
            }
            
        }
    }
}

/// When mapping to movies or shows from Trakt, the JSON is formatted differently to the Popcorn API. This struct is used to distinguish from which API the Media is being mapped from.
struct TraktContext: MapContext {}


// MARK: Trakt OAuth

@objc public protocol TraktManagerDelegate: class {
    /// Called when a user has successfully logged in.
    @objc optional func authenticationDidSucceed()
    
    /**
     Called if a user cancels the auth process or if the requests fail.
     
     - Parameter error: The underlying error.
     */
    @objc optional func authenticationDidFail(withError error: NSError)
}

extension TraktManager {
    
    /**
     First part of the Trakt authentication process.
     
     - Returns: A login view controller to be presented.
     */
    public func loginViewController() -> UIViewController {
        #if os(iOS)
            state = String.random(15)
            return SFSafariViewController(url: URL(string: Trakt.base + Trakt.auth + "/authorize?client_id=" + Trakt.apiKey + "&redirect_uri=PopcornTime%3A%2F%2Ftrakt&response_type=code&state=\(state!)")!)
        #else
            return TraktAuthenticationViewController(nibName: "TraktAuthenticationViewController", bundle: TraktAuthenticationViewController.bundle)
        #endif
    }
    
    /**
     Logout of Trakt.
     
     - Returns: Boolean value indicating the sucess of the operation.
     */
    @discardableResult public func logout() throws {
        return try OAuthCredential.delete(withIdentifier: "trakt")
    }
    
    /**
     Checks if user is authenticated with trakt.
     
     - Returns: Boolean value indicating the signed in status of the user.
     */
    public func isSignedIn() -> Bool {
        return OAuthCredential(identifier: "trakt") != nil
    }
    
    /**
     Generate code to authenticate device on web.
     
     - Parameter completion: The completion handler for the request containing the code for the user to enter to the validation url (`https://trakt.tv/activate/authorize`), the code for the device to get the access token, the expiery date of the displat code and the time interval that the program is to check whether the user has authenticated and an optional error if request fails.
     */
    internal func generateCode(completion: @escaping (String?, String?, Date?, TimeInterval?, NSError?) -> Void) {
        self.manager.request(Trakt.base + Trakt.auth + Trakt.device + Trakt.code, method: .post, parameters: ["client_id": Trakt.apiKey]).validate().responseJSON { (response) in
            guard let value = response.result.value as? [String: AnyObject], let displayCode = value["user_code"] as? String, let deviceCode = value["device_code"] as? String, let expire = value["expires_in"] as? Int, let interval = value["interval"]  as? Int else { completion(nil, nil, nil, nil, response.result.error as NSError?); return }
            completion(displayCode, deviceCode, Date().addingTimeInterval(Double(expire)), Double(interval), nil)
        }
    }
    
    /**
     Second part of the authentication process. Calls delegate upon completion.
     
     - Parameter url: The redirect URI recieved from step 1.
     */
    public func authenticate(_ url: URL) {
        defer { state = nil }
        
        guard let query = url.query?.queryString,
            let code = query["code"],
            query["state"] == state
            else {
                delegate?.authenticationDidFail?(withError: NSError(domain: "com.popcorntimetv.popcornkit.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured."]))
                return
        }
        
        DispatchQueue.global(qos: .default).async {
            do {
                try OAuthCredential(Trakt.base + Trakt.auth + Trakt.token,
                                    code: code,
                                    redirectURI: "PopcornTime://trakt",
                                    clientID: Trakt.apiKey,
                                    clientSecret: Trakt.apiSecret,
                                    useBasicAuthentication: false).store(withIdentifier: "trakt")
                self.delegate?.authenticationDidSucceed?()
            } catch let error as NSError {
                self.delegate?.authenticationDidFail?(withError: error)
            }
        }
    }
}
