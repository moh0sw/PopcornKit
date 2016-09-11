

import Foundation

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
