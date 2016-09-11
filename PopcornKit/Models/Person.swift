

import Foundation
import ObjectMapper

public protocol Person: Mappable {
    var name: String! { get set }
    var mediumImage: String? { get set }
    var smallImage: String? { get set }
    var largeImage: String? { get set }
}