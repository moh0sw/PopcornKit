
import XCTest
@testable import PopcornKit

class PopcornKitTests: XCTestCase {
    
    // MARK: - Movies
    
    func testMovies() {
        let expectation = self.expectation(description: "Fetch movies")
        PopcornKit.loadMovies(1, filterBy: .date) { (movies, error) in
            XCTAssertNotNil(movies, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    
    func testMovie() {
        let expectation = self.expectation(description: "Fetch single movie")
        PopcornKit.getMovieInfo("tt1431045") { (movie, error) in
            XCTAssertNotNil(movie, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    
    // MARK: - Shows
    
    func testShows() {
        let expectation = self.expectation(description: "Fetch shows")
        PopcornKit.loadShows(1, filterBy: .date) { (shows, error) in
            XCTAssertNotNil(shows, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testShow() {
        let expectation = self.expectation(description: "Fetch single show")
        PopcornKit.getShowInfo("tt2396758") { (show, error) in
            XCTAssertNotNil(show, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    // MARK: - Anime
    
    func testAnimes() {
        let expectation = self.expectation(description: "Fetch shows")
            PopcornKit.loadAnime(1, filterBy: .date) { (animes, error) in
            XCTAssertNotNil(animes, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testAnime() {
        let expectation = self.expectation(description: "Fetch single anime show")
        PopcornKit.getAnimeInfo("5646") { (anime, error) in
            XCTAssertNotNil(anime, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    // MARK: - Subtitles
    
    func testSubtitles() {
        let expectation = self.expectation(description: "Fetch subtitles for movie")
        SubtitlesManager.shared.search(imdbId: "tt1431045") { (subtitles, error) in
            XCTAssertNotEqual(subtitles.count, 0, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    // MARK: - Updates
    
    func testUpdates() {
        let expectation = self.expectation(description: "Update Check")
        UpdateManager.shared.checkVersion(.immediately) { success in
            XCTAssertTrue(success, "No updates available.")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    // MARK: - Trakt
    
    func testRelated() {
        let expectation = self.expectation(description: "Get related movie.")
        PopcornKit.getMovieInfo("tt1431045") { (movie, error) in
            XCTAssertNotNil(movie, error?.localizedDescription ?? "Unknown error")
            TraktManager.shared.getRelated(movie!, completion: { (media, error) in
                XCTAssertNotEqual(media.count, 0, error?.localizedDescription ?? "Unknown error")
                expectation.fulfill()
            })
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testWatched() {
        let expectation = self.expectation(description: "Get watchlist for a user.")
        TraktManager.shared.getWatched(forMediaOfType: .movies) { (ids, error) in
            XCTAssertNotEqual(ids.count, 0, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 30.0, handler: nil)
    }
    
    func testPeople() {
        let expectation = self.expectation(description: "Get a movies cast and crew.")
        TraktManager.shared.getPeople(forMediaOfType: .movies, id: "tt1431045") { (actors, crews, error) in
            XCTAssertNil(error, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testEpisode() {
        let expectation = self.expectation(description: "Get detailed episode information.")
        TraktManager.shared.getEpisodeMetadata("tt0944947", episodeNumber: 1, seasonNumber: 1) { (tvdbId, imdbId, error) in
            XCTAssertNil(error, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testCredits() {
        let expectation = self.expectation(description: "Get all movies that an actor was in.")
        TraktManager.shared.getMediaCredits(forPersonWithId: "nm0186505", mediaType: Movie.self) { (media, error) in
            XCTAssertNil(error, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 20.0, handler: nil)
    }
    
}
