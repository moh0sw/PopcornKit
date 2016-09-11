

import Foundation
import ObjectMapper

class TraktManager: NetworkManager {
    
    /// Creates new instance of TraktManager class
    static let sharedManager = TraktManager()
    
    /**
     Scrobbles current video.
     
     - Parameter id:            The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter progress:      The progress of the playing video. Possible values range from 0...1.
     - Parameter type:          The type of the item, either `Episode` or `Movie`.
     - Parameter status:        The status of the item.
     
     - Parameter completion:    Optional completion handler only called if an error is thrown.
     */
    func scrobble(id: String, progress: Float, type: Trakt.MediaType, status: Trakt.WatchedStatus, completion: ((error: NSError) -> Void)?) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {return}
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), { completion?(error: error) })
                }
            }
            var parameters = [String: AnyObject]()
            if type == .Movies {
                parameters = ["movie": ["ids": ["imdb": id]], "progress": progress * 100.0]
            } else {
                parameters = ["episode": ["ids": ["tvdb": Int(id)!]], "progress": progress * 100.0]
            }
            self.manager.request(.POST, Trakt.Base + Trakt.Scrobble + "/\(status.rawValue)", parameters: parameters, encoding: .JSON, headers: ["trakt-api-key": Trakt.APIKey, "trakt-api-version": "2", "Authorization": "Bearer \(credential.accessToken)"]).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error {
                    dispatch_async(dispatch_get_main_queue(), { completion?(error: error) })
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
    func getEpisodeMetadata(showId: String, episodeNumber: Int, seasonNumber: Int, completion:(largeImageUrl: String?, tvdbId: Int?, imdbId: String?, error: NSError?) -> Void) {
        self.manager.request(.GET, Trakt.Base + Trakt.Shows +  "/\(showId)" + Trakt.Seasons + "/\(seasonNumber)" + Trakt.Episodes + "/\(episodeNumber)", parameters: Trakt.Parameters.ExtendedImages, headers: Trakt.Headers.Default).validate().responseJSON { response in
            if let responseObject = response.result.value as? [String: AnyObject] {
                let image = responseObject["images"]?["screenshot"]??["full"] as? String
                let imdbId = responseObject["ids"]?["imdb"] as? String
                let tvdbId = responseObject["ids"]?["tvdb"] as? Int
                completion(largeImageUrl: image, tvdbId: tvdbId, imdbId: imdbId, error: nil)
            } else {
                completion(largeImageUrl: nil, tvdbId: nil, imdbId: nil, error: response.result.error)
            }
        }
    }
    
    /**
     Retrieves users previously watched videos.
     
     - Parameter forMediaOfType:    The type of the item (either movie or show).
     
     - Parameter completion:        The completion handler for the request containing an array of either imdbIds or tvdbIds depending on the type selected and an optional error.
     */
    func getWatched(forMediaOfType type: Trakt.MediaType, completion:(ids: [String], error: NSError?) -> Void) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else { return}
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), { completion(ids: [String](), error: error) })
                }
            }
            let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
            self.manager.request(.GET, Trakt.Base + Trakt.Sync + Trakt.Watched + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(queue: queue, options: .AllowFragments, completionHandler: { response in
                guard let responseObject = response.result.value as? [String: AnyObject] else { completion(ids: [String](), error: response.result.error); return}
                var ids = [String]()
                for (_, item) in responseObject {
                    if type == .Movies { ids.append(item["movie"]??["ids"]??["imdb"] as! String); continue}
                    var tvdbIds = [String](); let showImdbId = item["show"]??["ids"]??["imdb"] as! String
                    for (_, season) in item["seasons"] as! [String: AnyObject] {
                        let seasonNumber = season["number"] as! Int
                        for (_, episode) in season["episodes"] as! [String: AnyObject] {
                            let episodeNumber = episode["number"] as! Int; var id: String?
                            let semaphore = dispatch_semaphore_create(0)
                            self.getEpisodeMetadata(showImdbId, episodeNumber: episodeNumber, seasonNumber: seasonNumber, completion: { (_, tvdbId, _, _) in
                                if let tvdbId = tvdbId {id = String(tvdbId)}
                                dispatch_semaphore_signal(semaphore)
                            })
                            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                            if let id = id {tvdbIds.append(id)}
                        }
                    }
                    ids += tvdbIds
                }
                dispatch_async(dispatch_get_main_queue(), {
                    completion(ids: ids, error: nil)
                })
            })
        }
    }
    
    /**
     Retrieves users playback progress of video if applicable.
     
     - Parameter type:          The type of the item (either movie or episode).
     
     - Parameter completion:    The completion handler for the request containing a dictionary of either imdbIds or tvdbIds depending on the type selected as keys and the users corrisponding watched progress as values and an optional error. Eg. ["tt1431045": 0.5] means you have watched half of Deadpool.
     */
    func getPlaybackProgress(type: Trakt.MediaType, completion: (progressDict: [String: Float], error: NSError?) -> Void) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {return}
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), { completion(progressDict: [String: Float](), error: error) })
                }
            }
            self.manager.request(.GET, Trakt.Base + Trakt.Sync + Trakt.Playback + "/\(type.rawValue)", headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON { response in
                guard let responseObject = response.result.value as? [String: AnyObject] else { completion(progressDict: [String: Float](), error: response.result.error); return }
                var progressDict = [String: Float]()
                for (_, item) in responseObject {
                    var imdbId = item["movie"]??["ids"]??["imdb"] as? String
                    if let id = item["episode"]??["ids"]??["tvdb"] as? Int where imdbId == nil {imdbId = String(id)}
                    if let imdbId = imdbId, let progress = item["progress"] as? Float {
                        progressDict[imdbId] = progress/100.0
                    }
                }
                completion(progressDict: progressDict, error: nil)
            }
        }
    }
    
    /**
     Removes a movie or episode from a users watch history.
     
     - Parameter type:          The type of the item (movie or episode).
     - Parameter id:            The imdbId or tvdbId of the movie, episode or show.
     
     - Parameter completion:    An optional completion handler called only if an error is thrown.
     */
    func removeItemFromHistory(type: Trakt.MediaType, id: String, completion: ((error: NSError) -> Void)?) {
        guard var credential = OAuthCredential.retrieveCredentialWithIdentifier("trakt") else {return}
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
            if credential.expired {
                do {
                    credential = try OAuthCredential(URLString: Trakt.Base + Trakt.Auth + Trakt.Token, refreshToken: credential.refreshToken!, clientID: Trakt.APIKey, clientSecret: Trakt.APISecret, useBasicAuthentication: false)!
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), {completion?(error: error) })
                }
            }
            var parameters = [String: AnyObject]()
            if type == .Movies {
                parameters = ["movies": [["ids": ["imdb": id]]]]
            } else if type == .Episodes {
                parameters = ["episodes": [["ids": ["tvdb": Int(id)!]]]]
            }
            
            self.manager.request(.POST, Trakt.Base + Trakt.Sync + Trakt.History + Trakt.Remove , parameters: parameters, encoding: .JSON, headers: Trakt.Headers.Authorization(credential.accessToken)).validate().responseJSON(completionHandler: { response in
                if let error = response.result.error {dispatch_async(dispatch_get_main_queue(), { completion?(error: error)})
                }
            })
        }
    }
    
    /**
     Retrieves cast and crew information for a movie or show.
     
     - Parameter forMediaOfType:    The type of the item (movie or show **not anime**). Anime is supported but is referenced as a show not as its own type.
     - Parameter id:                The id of the movie, show or anime.
     
     - Parameter completion:        The completion handler for the request containing an array of actors, array of crews and an optional error.
     */
    func getPeople(forMediaOfType type: Trakt.MediaType, id: String, completion: (actors: [Actor], crews: [Crew], error: NSError?) -> Void) {
        self.manager.request(.GET, Trakt.Base + "/\(type.rawValue)/\(id)" + Trakt.People, parameters: Trakt.Parameters.ExtendedImages, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let responseObject = response.result.value as? [String: AnyObject] else { completion(actors: [Actor](), crews:  [Crew](), error: response.result.error); return}
            let actors = Mapper<Actor>().mapArray(responseObject["cast"]) ?? [Actor]()
            var crews = [Crew]()
            for (role, crew) in responseObject["crew"] as! [String: [AnyObject]] {
                if let crew = Mapper<Crew>().mapArray(crew) {
                    for var person in crew {person.roleType = Role(rawValue: role); crews.append(person)}
                }
            }
            completion(actors: actors, crews: crews, error: nil)
        }
    }
    
    /**
     Retrieves related media.
     
     - Parameter forMediaOfType:    The type of the item (movie or show **not anime**). Anime is supported but is referenced as a show not as its own type.
     - Parameter id:                The id of the movie, show or anime.
     
     - Returns: Array of imageUrls, titles and ids.
     */
    func getRelated<T: Media>(id: String, completion: (media: [T], error: NSError?) -> Void) {
        self.manager.request(.GET, Trakt.Base + (T.self is Movie ? "/movies" : "/shows") + "/\(id)" + Trakt.Related, parameters: Trakt.Parameters.ExtendedAll, headers: Trakt.Headers.Default).validate().responseJSON { response in
            guard let responseObject = response.result.value as? [String: AnyObject] else { completion(media: [T](), error: response.result.error); return }
            completion(media: Mapper<T>(context: TraktContext()).mapArray(responseObject) ?? [T](), error: nil)
        }
    }
}

/// When mapping to movies or shows from Trakt, the JSON is formatted differently to the Popcorn API. This struct is used to distinguish from which API the Media is being mapped from.
struct TraktContext: MapContext {}
