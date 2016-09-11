
import XCTest
@testable import PopcornKit

class PopcornKitTests: XCTestCase {
    
    // MARK: - Movies
    
    func testMovies() {
        let expectation = self.expectationWithDescription("Fetch movies")
        MovieManager.sharedManager.load(1, filterBy: .Date) { (movies, error) in
            XCTAssertNotNil(movies, "No results found")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    
    func testMovie() {
        let expectation = self.expectationWithDescription("Fetch single movie")
        MovieManager.sharedManager.getInfo("tt1431045") { (movie, error) in
            XCTAssertNotNil(movie, "No results found.")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    
    // MARK: - Shows
    
    func testShows() {
        let expectation = self.expectationWithDescription("Fetch shows")
        ShowManager.sharedManager.load(1, filterBy: .Date) { (shows, error) in
            XCTAssertNotNil(shows, "No results found")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testShow() {
        let expectation = self.expectationWithDescription("Fetch single show")
        ShowManager.sharedManager.getInfo("tt2396758") { (show, error) in
            XCTAssertNotNil(show, "No results found.")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    // MARK: - Anime
    
    func testAnimes() {
        let expectation = self.expectationWithDescription("Fetch shows")
        AnimeManager.sharedManager.load(1, filterBy: .Date) { (animes, error) in
            XCTAssertNotNil(animes, "No results found")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    func testAnime() {
        let expectation = self.expectationWithDescription("Fetch single anime show")
        AnimeManager.sharedManager.getInfo("5646") { (anime, error) in
            XCTAssertNotNil(anime, "No results found.")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }
    
    // MARK: - Subtitles
    
    func testSubtitles() {
        let expectation = self.expectationWithDescription("Fetch subtitles for movie")
        SubtitlesManager.sharedManager.login({
            SubtitlesManager.sharedManager.search(imdbId: "tt1431045") { (subtitles, error) in
                XCTAssertNotNil(subtitles, "No results found.")
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
    
}
