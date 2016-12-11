
import Foundation

/// Class for managing a users watch history. **Only available for movies, and episodes**.
open class WatchedlistManager {
    
    private let currentType: Trakt.MediaType
    
    /// Creates new instance of WatchedlistManager class with type of Movies.
    open static let movie = WatchedlistManager(type: .movies)
    
    /// Creates new instance of WatchedlistManager class with type of Episodes.
    open static let episode = WatchedlistManager(type: .episodes)
    
    /// Creates new instance of WatchedlistManager class with type of Shows.
    open static let show = WatchedlistManager(type: .shows)
    
    private init(type: Trakt.MediaType) {
        currentType = type
    }
    
    /** 
     Toggles a users watched status on the passed in media id and syncs with Trakt if available.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     */
    open func toggle(_ id: String) {
        isAdded(id) ? remove(id): add(id)
    }
    
    /**
     Adds movie or episode to watchedlist and syncs with Trakt if available.
     
     - Parameter id: The imdbId or tvdbId of the movie or episode.
     */
    open func add(_ id: String) {
        TraktManager.shared.scrobble(id, progress: 1, type: currentType, status: .finished)
        var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] ?? [String]()
        !array.contains(id) ? array.append(id) : ()
        UserDefaults.standard.set(array, forKey: "\(currentType.rawValue)Watchedlist")
    }
    
    /**
     Removes movie or episode from a users watchedlist and syncs with Trakt if available.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     */
    open func remove(_ id: String) {
        TraktManager.shared.remove(id, fromWatchedlistOfType: currentType)
        if var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String],
            let index = array.index(of: id) {
            array.remove(at: index)
            UserDefaults.standard.set(array, forKey: "\(currentType.rawValue)Watchedlist")
        }
    }
    
    /**
     Checks if movie or episode is in the watchedlist.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     
     - Returns: Boolean indicating if movie or episode is in watchedlist.
     */
    open func isAdded(_ id: String) -> Bool {
        if let array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] {
            return array.contains(id)
        }
        return false
    }
    
    /**
     Gets watchedlist locally first and then from Trakt.
     
     - Returns: Completion block called twice; first returns locally stored watchedlist (may be out of date), second time returns the updated watchedlist from Trakt if available.
     */
    open func getWatched(_ completion: (() -> Void)? = nil) {
        var array = UserDefaults.standard.object(forKey: "\(currentType.rawValue)Watchedlist") as? [String] ?? [String]()
        completion?()
        TraktManager.shared.getWatched(forMediaOfType: currentType) { [unowned self] (watchedIds, error) in
            guard error == nil else {return}
            array = watchedIds
            UserDefaults.standard.set(array, forKey: "\(self.currentType.rawValue)Watchedlist")
            completion?()
        }
    }
    
    /**
     Stores movie progress and syncs with Trakt if available.
     
     - Parameter progress:      The progress of the playing video. Possible values range from 0...1.
     - Parameter forId:         The imdbId for movies and tvdbId for episodes of the media that is playing.
     - Parameter withStatus:    The status of the item.
     */
    open func setCurrentProgress(_ progress: Float, forId id: String, withStatus status: Trakt.WatchedStatus) {
        TraktManager.shared.scrobble(id, progress: progress, type: currentType, status: status)
        var dict = UserDefaults.standard.object(forKey: "\(currentType.rawValue)VideoProgress") as? [String: Float] ?? [String: Float]()
        dict[id] = progress
        progress >= 0.8 ? add(id) : ()
        UserDefaults.standard.set(dict, forKey: "\(currentType.rawValue)VideoProgress")
    }
    
    /**
     Retrieves latest progress from Trakt and updates local storage. 
     
     - Important: Local watchedlist may be more up-to-date than Trakt version but local version will be replaced with Trakt version regardless.
     
     - Parameter completion: Optional completion handler called when progress has been retrieved. May never be called if user hasn't authenticated with Trakt.
     */
    open func syncTraktProgress(completion: (() -> Void)? = nil) {
        TraktManager.shared.getPlaybackProgress(forMediaOfType: currentType) { [unowned self] (dict, error) in
            guard error == nil else {return}
            UserDefaults.standard.set(dict, forKey: "\(self.currentType.rawValue)VideoProgress")
            completion?()
        }
    }
    
    /**
     Gets watched progress for movie or epsiode.
     
     - Parameter id: The imdbId for movie or tvdbId for episode.
     
     - Returns: The users last play position progress from 0.0 to 1.0 (if any).
     */
    open func currentProgress(_ id: String) -> Float {
        if let dict = UserDefaults.standard.object(forKey: "\(currentType.rawValue)VideoProgress") as? [String: Float],
            let progress = dict[id] {
            return progress
        }
        return 0.0
    }
}

