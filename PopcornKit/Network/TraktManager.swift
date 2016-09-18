

import ObjectMapper
import Alamofire

#if os(iOS)
    import SafariServices
#endif

public protocol TraktDelegate: class {
    /// Called when a user has successfully logged in.
    func AuthenticationDidSucceed()
    
    /**
     Called if a user cancels the auth process or if the requests fail.
     
     - Parameter error: The underlying error.
     */
    func AuthenticationDidFail(withError error: NSError)
}

open class TraktManager: NetworkManager {
    
    
    /// Creates new instance of TraktManager class
    open static let shared = TraktManager()
    
    /// OAuth state parameter added for extra security against cross site forgery.
    fileprivate var state: String!
    
    /// The delegate for the Trakt Authentication process.
    open weak var delegate: TraktDelegate?
    
    /**
     Scrobbles current video.
     
     - Parameter id:            The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter progress:      The progress of the playing video. Possible values range from 0...1.
     - Parameter type:          The type of the item, either `Episode` or `Movie`.
     - Parameter status:        The status of the item.
     
     - Parameter completion:    Optional completion handler only called if an error is thrown.
     */
    open func scrobble(_ id: String, progress: Float, type: Trakt.MediaType, status: Trakt.WatchedStatus, completion: ((_ error: NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {return}
        DispatchQueue.global(qos: .background).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion?(error) })
                }
            }
            var parameters = [String: Any]()
            if type == .Movies {
                parameters = ["movie": ["ids": ["imdb": id]], "progress": progress * 100.0]
            } else {
                parameters = ["episode": ["ids": ["tvdb": Int(id)!]], "progress": progress * 100.0]
            }
            self.manager.request(Trakt.Base + Trakt.Scrobble + "/\(status.rawValue)", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error {
                    DispatchQueue.main.async(execute: { completion?(error as NSError) })
                }
            })
        }
    }
    
    /**
     Load episode metadata from API.
     
     - Parameter show:          The imdbId or slug for the show.
     - Parameter episodeNumber: The number of the episode in relation to its current season.
     - Parameter seasonNumber:  The season of which the episode is in.
     
     - Parameter completion:    The completion handler for the request containing an optional largeImageUrl, optional tvdbId and optional imdbId.
     */
    open func getEpisodeMetadata(_ showId: String, episodeNumber: Int, seasonNumber: Int, completion: @escaping (_ largeImageUrl: String?, _ tvdbId: Int?, _ imdbId: String?, _ error: NSError?) -> Void) {
        self.manager.request(Trakt.Base + Trakt.Shows +  "/\(showId)" + Trakt.Seasons + "/\(seasonNumber)" + Trakt.Episodes + "/\(episodeNumber)", parameters: Trakt.Parameters.ExtendedImages, headers: Trakt.Headers.Default).validate().responseJSON { response in
            if let responseObject = response.result.value as? [String: [String: AnyObject]] {
                let image = responseObject["images"]?["screenshot"]?["full"] as? String
                let imdbId = responseObject["ids"]?["imdb"] as? String
                let tvdbId = responseObject["ids"]?["tvdb"] as? Int
                completion(image, tvdbId, imdbId, nil)
            } else {
                completion(nil, nil, nil, response.result.error as NSError?)
            }
        }
    }
    
    /**
     Retrieves users previously watched videos.
     
     - Parameter forMediaOfType:    The type of the item (either movie or show).
     
     - Parameter completion:        The completion handler for the request containing an array of either imdbIds or tvdbIds depending on the type selected and an optional error.
     */
    open func getWatched(forMediaOfType type: Trakt.MediaType, completion:@escaping (_ ids: [String], _ error: NSError?) -> Void) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else { return}
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion([String](), error) })
                }
            }
            let queue = DispatchQueue(label: "com.popcorn-time.response.queue", attributes: .concurrent)
            self.manager.request(Trakt.Base + Trakt.Sync + Trakt.Watched + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(queue: queue, options: .allowFragments, completionHandler: { response in
                guard let responseObject = response.result.value as? [String: [String: [String: AnyObject]]] else { completion([String](), response.result.error as NSError?); return}
                var ids = [String]()
                for (_, item) in responseObject {
                    if type == .Movies { ids.append(item["movie"]?["ids"]?["imdb"] as! String); continue}
                    var tvdbIds = [String](); let showImdbId = item["show"]?["ids"]?["imdb"] as! String
                    for (_, season) in item["seasons"]! {
                        let seasonNumber = season["number"] as! Int
                        for (_, episode) in season["episodes"] as! [String: AnyObject] {
                            let episodeNumber = episode["number"] as! Int; var id: String?
                            let semaphore = DispatchSemaphore(value: 0)
                            self.getEpisodeMetadata(showImdbId, episodeNumber: episodeNumber, seasonNumber: seasonNumber, completion: { (_, tvdbId, _, _) in
                                if let tvdbId = tvdbId {id = String(tvdbId)}
                                semaphore.signal()
                            })
                            semaphore.wait()
                            if let id = id {tvdbIds.append(id)}
                        }
                    }
                    ids += tvdbIds
                }
                DispatchQueue.main.async(execute: {
                    completion(ids, nil)
                })
            })
        }
    }
    
    /**
     Retrieves users playback progress of video if applicable.
     
     - Parameter type:          The type of the item (either movie or episode).
     
     - Parameter completion:    The completion handler for the request containing a dictionary of either imdbIds or tvdbIds depending on the type selected as keys and the users corrisponding watched progress as values and an optional error. Eg. ["tt1431045": 0.5] means you have watched half of Deadpool.
     */
    open func getPlaybackProgress(_ type: Trakt.MediaType, completion: @escaping (_ progressDict: [String: Float], _ error: NSError?) -> Void) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {return}
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { completion([String: Float](), error) })
                }
            }
            self.manager.request(Trakt.Base + Trakt.Sync + Trakt.Playback + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                guard let responseObject = response.result.value as? [String: AnyObject] else { completion([String: Float](), response.result.error as NSError?); return }
                var progressDict = [String: Float]()
                for (_, item) in responseObject {
                    var imdbId = (item["movie"] as? [String: [String: AnyObject]])?["ids"]?["imdb"] as? String
                    if let id = (item["episode"] as? [String: [String: AnyObject]])?["ids"]?["tvdb"] as? Int , imdbId == nil {imdbId = String(id)}
                    if let imdbId = imdbId, let progress = item["progress"] as? Float {
                        progressDict[imdbId] = progress/100.0
                    }
                }
                completion(progressDict, nil)
            }
        }
    }
    
    /**
     Removes a movie or episode from a users watch history.
     
     - Parameter type:          The type of the item (movie or episode).
     - Parameter id:            The imdbId or tvdbId of the movie, episode or show.
     
     - Parameter completion:    An optional completion handler called only if an error is thrown.
     */
    open func removeItemFromHistory(_ type: Trakt.MediaType, id: String, completion: ((_ error: NSError) -> Void)? = nil) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {return}
        DispatchQueue.global(qos: .userInitiated).async {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: {completion?(error) })
                }
            }
            var parameters = [String: Any]()
            if type == .Movies {
                parameters = ["movies": [["ids": ["imdb": id]]]]
            } else if type == .Episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            }
            self.manager.request(Trakt.Base + Trakt.Sync + Trakt.History + Trakt.Remove, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error {DispatchQueue.main.async(execute: {completion?(error as NSError)})}
            })
        }
    }
    
    /**
     Retrieves cast and crew information for a movie or show.
     
     - Parameter forMediaOfType:    The type of the item (movie or show **not anime**). Anime is supported but is referenced as a show not as its own type.
     - Parameter id:                The id of the movie, show or anime.
     
     - Parameter completion:        The completion handler for the request containing an array of actors, array of crews and an optional error.
     */
    open func getPeople(forMediaOfType type: Trakt.MediaType, id: String, completion: @escaping (_ actors: [Actor], _ crews: [Crew], _ error: NSError?) -> Void) {
        self.manager.request(Trakt.Base + "/\(type.rawValue)/\(id)" + Trakt.People, parameters: Trakt.Parameters.ExtendedImages, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let responseObject = response.result.value as? [String: Any],
                let people = responseObject["crew"] as? [String: [AnyObject]],
                let cast = responseObject["cast"] as? [[String: Any]] else { completion([Actor](), [Crew](), response.result.error as NSError?); return}
            let actors = Mapper<Actor>().mapArray(JSONObject: cast) ?? [Actor]()
            var crews = [Crew]()
            for (role, crew) in people {
                if let crew = Mapper<Crew>().mapArray(JSONObject: crew) {
                    for var person in crew {person.roleType = Role(rawValue: role); crews.append(person)}
                }
            }
            completion(actors, crews, nil)
        }
    }
    
    /**
     Retrieves related media.
     
     - Parameter media:         The media you would like to get more information about. **Please note:** only the imdbdId is used but an object needs to be passed in for Swift generics to work so creating a blank object with only an imdbId variable initialised will suffice if necessary.
     
     - Parameter completion:    The requests completion handler containing array of related movies and an optional error.
     */
    open func getRelated<T: Media>(_ media: T, completion: @escaping (_ media: [T], _ error: NSError?) -> Void) {
        self.manager.request(Trakt.Base + (media is Movie ? Trakt.Movies : Trakt.Shows) + "/\(media.id)" + Trakt.Related, parameters: Trakt.Parameters.ExtendedAll, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let value = response.result.value else { completion([T](), response.result.error as NSError?); return }
            completion(Mapper<T>(context: TraktContext()).mapArray(JSONObject: value) ?? [T](), nil)
        }
    }
    
    /**
     Retrieves movies or shows that the person in cast/crew in.
     
     - Parameter forPersonWithId:   The id of the person you would like to get more information about.
     - Parameter media:             Just the type of the media is required for Swift generics to work.
     
     - Parameter completion:        The requests completion handler containing array of movies and an optional error.
     */
    open func getMediaCredits<T: Media>(forPersonWithId id: String, media: T.Type, completion: @escaping (_ media: [T], _ error: NSError?) -> Void) {
        self.manager.request(Trakt.Base + Trakt.People + "/\(id)" + (media is Movie.Type ? Trakt.Movies : Trakt.Shows), parameters: Trakt.Parameters.ExtendedAll, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let responseObject = response.result.value as? [String: Any] else { completion([T](), response.result.error as NSError?); return }
            var movies = [T]()
            if let people = responseObject["crew"] as? [String: [[String: Any]]] {
                for (_, item) in people {
                    for item in item { if let media = Mapper<T>(context: TraktContext()).map(JSONObject: item["movie"]) { movies.append(media) } }
                }
            }
            if let cast = responseObject["cast"] as? [[String: Any]] {
                for item in cast { if let media = Mapper<T>(context: TraktContext()).map(JSONObject: item["movie"]) { movies.append(media) }}
            }
            completion(movies, nil)
        }
    }
}

/// When mapping to movies or shows from Trakt, the JSON is formatted differently to the Popcorn API. This struct is used to distinguish from which API the Media is being mapped from.
struct TraktContext: MapContext {}


// MARK: Trakt OAuth

extension TraktManager {
    public func login() -> UIViewController {
        #if os(iOS)
            state = String.random(15)
            return SFSafariViewController(url: URL(string: Trakt.Base + Trakt.Auth + "/authorize?client_id=" + Trakt.APIKey + "&redirect_uri=PopcornTime%3A%2F%2Ftrakt&response_type=code&state=\(state)")!)
        #else
            return UIViewController()
        #endif
    }
    
    public func authenticate(_ url: URL) {
        defer { state = nil }
        
        guard let query = url.query?.queryString,
            let code = query["code"],
            query["state"] == state
            else {
                delegate?.AuthenticationDidFail(withError: NSError(domain: "com.popcornkit.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured."]))
                return
        }
        
        DispatchQueue.global(qos: .default).async {
            do {
                guard let credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token,
                                                           code: code,
                                                           redirectURI: "PopcornTime://trakt",
                                                           clientID: Trakt.APIKey,
                                                           clientSecret: Trakt.APISecret,
                                                           useBasicAuthentication: false)
                    else {
                        throw NSError(domain: "com.popcornkit.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "An unknown error occured."])
                }
                OAuthCredential.storeCredential(credential, identifier: "trakt")
                self.delegate?.AuthenticationDidSucceed()
            } catch let error as NSError {
                self.delegate?.AuthenticationDidFail(withError: error)
            }
        }
    }
}
