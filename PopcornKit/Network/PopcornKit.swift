

import Foundation
import Alamofire

#if os(iOS)
    import SRT2VTT
#endif

/**
 Load Anime from API.
 
 - Parameter page:       The page number to load.
 - Parameter filterBy:   Sort the response by Popularity, Year, Date Rating, Alphabet or Trending.
 - Paramter genre:       Only return anime that match the provided genre.
 - Parameter searchTerm: Only return animes that match the provided string.
 - Parameter orderBy:    Ascending or descending.
 
 - Parameter completion: Completion handler for the request. Returns array of animes upon success, error upon failure.
 */
public func loadAnime(
    page: Int,
    filterBy filter: AnimeManager.filters,
    genre: AnimeManager.genres = .All,
    searchTerm: String? = nil,
    orderBy order: AnimeManager.orders = .Descending,
    completion: (shows: [Show]?, error: NSError?) -> Void) {
    AnimeManager.sharedManager.load(
        page,
        filterBy: filter,
        genre: genre,
        searchTerm: searchTerm,
        orderBy: order,
        completion: completion)
}

/**
 Get more anime information.
 
 - Parameter id:            The identification code of the anime.
 
 - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
 */
public func getAnimeInfo(id: String, completion: (show: Show?, error: NSError?) -> Void) {
    AnimeManager.sharedManager.getInfo(id, completion: completion)
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
public func loadShows(
    page: Int,
    filterBy filter: ShowManager.filters,
    genre: ShowManager.genres = .All,
    searchTerm: String? = nil,
    orderBy order: ShowManager.orders = .Descending,
    completion: (shows: [Show]?, error: NSError?) -> Void) {
    ShowManager.sharedManager.load(
        page,
        filterBy: filter,
        genre: genre,
        searchTerm: searchTerm,
        orderBy: order,
        completion: completion)
}

/**
 Get more show information.
 
 - Parameter imbdId:        The imbd identification code of the show.
 
 - Parameter completion:    Completion handler for the request. Returns show upon success, error upon failure.
 */
public func getShowInfo(imdbId: String, completion: (show: Show?, error: NSError?) -> Void) {
    ShowManager.sharedManager.getInfo(imdbId, completion: completion)
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
public func loadMovies(
    page: Int,
    filterBy filter: MovieManager.filters,
    genre: MovieManager.genres = .All,
    searchTerm: String? = nil,
    orderBy order: MovieManager.orders = .Descending,
    completion: (movies: [Movie]?, error: NSError?) -> Void) {
    MovieManager.sharedManager.load(
        page,
        filterBy: filter,
        genre: genre,
        searchTerm: searchTerm,
        orderBy: order,
        completion: completion)
}

/**
 Get more movie information.
 
 - Parameter imbdId: The imbd identification code for the movie.
 
 - Parameter completion:    Completion handler for the request. Returns movie upon success, error upon failure.
 */
public func getMovieInfo(imdbId: String, completion: (movie: Movie?, error: NSError?) -> Void) {
    MovieManager.sharedManager.getInfo(imdbId, completion: completion)
}

/**
 Download torrent file from link.
 
 - Parameter path:          The path to the torrent file you would like to download.
 
 - Parameter completion:    Completion handler for the request. Returns downloaded torrent url upon success, error upon failure.
 */
public func downloadTorrentFile(path: String, completion: (url: String?, error: NSError?) -> Void) {
    var finalPath: NSURL!
    Alamofire.download(.GET, path, destination: { (temporaryURL, response) -> NSURL in
        finalPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(response.suggestedFilename!)
        if NSFileManager.defaultManager().fileExistsAtPath(finalPath.relativePath!) {
            try! NSFileManager.defaultManager().removeItemAtPath(finalPath.relativePath!)
        }
        return finalPath
    }).validate().response { (_, _, _, error) in
        guard error == nil else {completion(url: nil, error: error); return }
        completion(url: finalPath.path!, error: nil)
    }
}

/**
 Download subtitle file from link.
 
 - Parameter path:              The path to the subtitle file you would like to download.
 - Parameter fileName:          An optional file name you can provide.
 - Parameter downloadDirectory: You can opt to change the download location of the file. Defaults to `NSTemporaryDirectory/Subtitles`.
 - Parameter convertToVTT:      You can opt to convert the downloaded subtitle to VTT format. Defaults to `false`. Not available on tvOS.
 
 - Parameter completion:    Completion handler for the request. Returns downloaded subtitle url upon success, error upon failure.
 */
public func downloadSubtitleFile(
    path: String,
    fileName suggestedName: String? = nil,
    downloadDirectory directory: NSURL = NSURL(fileURLWithPath: NSTemporaryDirectory()),
    convertToVTT: Bool = false,
    completion: (subtitlePath: NSURL?, error: NSError?) -> Void) {
    
    var downloadDirectory: NSURL!
    var zippedFilePath: NSURL!
    var fileName: String!
    Alamofire.download(.GET, path, destination: { (temporaryURL, response) -> NSURL in
        fileName = suggestedName ?? response.suggestedFilename!
        downloadDirectory = directory.URLByAppendingPathComponent("Subtitles")
        if !NSFileManager.defaultManager().fileExistsAtPath(downloadDirectory.path!) {
            try! NSFileManager.defaultManager().createDirectoryAtURL(downloadDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        zippedFilePath = downloadDirectory.URLByAppendingPathComponent(fileName)
        if NSFileManager.defaultManager().fileExistsAtPath(zippedFilePath.path!) { try! NSFileManager.defaultManager().removeItemAtPath(zippedFilePath.path!) }
        return zippedFilePath
    }).validate().response { (_, _, _, error) in
        guard error == nil else {completion(subtitlePath: nil, error: error); return }
        let filePath = downloadDirectory.URLByAppendingPathExtension(fileName.stringByReplacingOccurrencesOfString(".gz", withString: ""))
        NSFileManager.defaultManager().createFileAtPath(filePath.path!, contents: NSFileManager.defaultManager().contentsAtPath(zippedFilePath.path!)?.gunzippedData(), attributes: nil)
         #if os(iOS)
            completion(subtitlePath: convertToVTT ? SRT.sharedConverter().convertFileToVTT(filePath) : filePath, error: nil)
        #else
            completion(subtitlePath: filePath, error: nil)
        #endif
        
        
    }
}


