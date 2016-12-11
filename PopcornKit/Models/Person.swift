

import Foundation
import ObjectMapper

/// Generic person protocol.
public protocol Person: Mappable {
    var name: String { get }
    var tmdbId: Int { get }
    var imdbId: String { get }
    var mediumImage: String? { get }
    var smallImage: String? { get }
    var largeImage: String? { get set }
}
