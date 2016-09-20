
import Foundation

/// Class for managing a users watchlist.
open class WatchlistManager {
    
    private var currentType: Trakt.MediaType
    
    /// Creates new instance of WatchlistManager class with type of Movies.
    open static let movie = WatchlistManager(type: .movies)
    
    /// Creates new instance of WatchlistManager class with type of Episodes.
    open static let episode = WatchlistManager(type: .episodes)
    
    /// Creates new instance of WatchlistManager class with type of Shows.
    static let show = WatchlistManager(type: .shows)
    
    private init(type: Trakt.MediaType) {
        currentType = type
    }
    
    /** 
     Toggles a users watched status on the passed in media id and syncs with Trakt.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     */
    open func toggleWatched(_ id: String) {
        isWatched(id) ? remove(id): add(id)
    }
    /**
     Adds movie or episode to watchlists and syncs with Trakt.
     
     - Parameter id:    The imdbId or tvdbId of the media.
     */
    open func add(_ id: String) {
        TraktManager.shared.scrobble(id, progress: 1, type: currentType, status: .finished)
        var array = UserDefaults.standard.object(forKey: "Watchlist") as? [String]
        array = array ?? [String]()
        array!.append(id)
        UserDefaults.standard.set(array, forKey: "Watchlist")
    }
    /**
     Removes movie or episode to watchlists and syncs with Trakt.
     
     - Parameter id: The Imdb identification code of the episode or tv.
     */
    open func remove(_ id: String) {
        TraktManager.shared.removeItemFromHistory(currentType, id: id)
        if var array = UserDefaults.standard.object(forKey: "Watchlist") as? [String] {
            for (index, item) in array.enumerated() {
                if item == id {
                    array.remove(at: index)
                }
            }
            UserDefaults.standard.set(array, forKey: "Watchlist")
        }
    }
    /**
     Checks if movie or episode is in the watchlist.
     
     - Parameter id: The Imdb identification code of the movie or episode.
     
     - Returns: Boolean indicating if movie or episode is in watchlist.
     */
    open func isWatched(_ id: String) -> Bool {
        if let array = UserDefaults.standard.object(forKey: "Watchlist") as? [String] {
            return array.contains(id)
        }
        return false
    }
    /**
     Gets watchlist locally first and then from Trakt.
     
     - Returns: Completion block called twice; first returns locally stored watchlist (may be out of date), second time returns the updated watchlist from Trakt.
     */
    open func getWatched(_ completion:@escaping () -> Void) {
        var array = UserDefaults.standard.object(forKey: "Watchlist") as? [String]
        array = array ?? [String]()
        completion()
        TraktManager.shared.getWatched(forMediaOfType: currentType) { (watchedIds, error) in
            guard error == nil else {return}
            array!.removeAll()
            array = watchedIds
            UserDefaults.standard.set(array, forKey: "Watchlist")
            completion()
        }
    }
    /**
     Gets progress locally first and then from Trakt.
     */
    open func getProgress() {
        var progressDict = UserDefaults.standard.object(forKey: "VideoProgress") as? [String: Float]
        progressDict = progressDict ?? [String: Float]()
        TraktManager.shared.getPlaybackProgress(currentType) { (dict, error) in
            guard error == nil else {return}
            progressDict!.removeAll()
            progressDict = dict
            UserDefaults.standard.set(progressDict, forKey: "VideoProgress")
        }
    }
    /**
     Gets watched progress for movie or epsiode.
     
     - Parameter id: The Imdb identification code of the movie or episode.
     
     - Returns: The progress (if any) of the movie or episode.
     */
    open func currentProgress(_ id: String) -> Float {
        if let dict = UserDefaults.standard.object(forKey: "VideoProgress") as? [String: Float],
            let progress = dict[id] {
            return progress
        }
        return 0.0
    }
}

