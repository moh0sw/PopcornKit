
import XCTest
@testable import PopcornKitIOS

class PopcornKitTests: XCTestCase {
    
    // MARK: - Movies
    
    func testMovies() {
        let expectation = self.expectationWithDescription("Fetch movies")
        MovieManager.sharedManager.load(1, filterBy: .Date) { (movies, error) in
            XCTAssertNotNil(movies, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    
    func testMovie() {
        let expectation = self.expectationWithDescription("Fetch single movie")
        MovieManager.sharedManager.getInfo("tt1431045") { (movie, error) in
            XCTAssertNotNil(movie, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    
    // MARK: - Shows
    
    func testShows() {
        let expectation = self.expectationWithDescription("Fetch shows")
        ShowManager.sharedManager.load(1, filterBy: .Date) { (shows, error) in
            XCTAssertNotNil(shows, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testShow() {
        let expectation = self.expectationWithDescription("Fetch single show")
        ShowManager.sharedManager.getInfo("tt2396758") { (show, error) in
            XCTAssertNotNil(show, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    // MARK: - Anime
    
    func testAnimes() {
        let expectation = self.expectationWithDescription("Fetch shows")
        AnimeManager.sharedManager.load(1, filterBy: .Date) { (animes, error) in
            XCTAssertNotNil(animes, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testAnime() {
        let expectation = self.expectationWithDescription("Fetch single anime show")
        AnimeManager.sharedManager.getInfo("5646") { (anime, error) in
            XCTAssertNotNil(anime, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    // MARK: - Subtitles
    
    func testSubtitles() {
        let expectation = self.expectationWithDescription("Fetch subtitles for movie")
        SubtitlesManager.sharedManager.login({
            SubtitlesManager.sharedManager.search(imdbId: "tt1431045") { (subtitles, error) in
                XCTAssertNotEqual(subtitles.count, 0, error?.localizedDescription ?? "Unknown error")
                expectation.fulfill()
            }
        })
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    // MARK: - Updates
    
    func testUpdates() {
        let expectation = self.expectationWithDescription("Update Check")
        UpdateManager.sharedManager.checkVersion(.Immediately) { success in
            XCTAssertTrue(success, "No updates available.")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    // MARK: - Trakt
    
    func testRelated() {
        let expectation = self.expectationWithDescription("Get related movie.")
        MovieManager.sharedManager.getInfo("tt1431045") { (movie, error) in
            XCTAssertNotNil(movie, error?.localizedDescription ?? "Unknown error")
            TraktManager.sharedManager.getRelated(movie!, completion: { (media, error) in
                XCTAssertNotEqual(media.count, 0, error?.localizedDescription ?? "Unknown error")
                expectation.fulfill()
            })
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testWatched() {
        let expectation = self.expectationWithDescription("Get watchlist for a user.")
        TraktManager.sharedManager.getWatched(forMediaOfType: .Movies) { (ids, error) in
            XCTAssertNotEqual(ids.count, 0, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(30.0, handler: nil)
    }
    
    func testPeople() {
        let expectation = self.expectationWithDescription("Get a movies cast and crew.")
        TraktManager.sharedManager.getPeople(forMediaOfType: .Movies, id: "tt1431045") { (actors, crews, error) in
            XCTAssertNil(error, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testEpisode() {
        let expectation = self.expectationWithDescription("Get detailed episode information.")
        TraktManager.sharedManager.getEpisodeMetadata("tt0944947", episodeNumber: 1, seasonNumber: 1) { (largeImageUrl, tvdbId, imdbId, error) in
            XCTAssertNil(error, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testCredits() {
        let expectation = self.expectationWithDescription("Get all movies that an actor was in.")
        TraktManager.sharedManager.getMediaCredits(forPersonWithId: "nm0186505", media: Movie.self) { (media, error) in
            XCTAssertNil(error, error?.localizedDescription ?? "Unknown error")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
}
