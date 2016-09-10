

import Foundation
import ObjectMapper

protocol Media: Mappable {
    var title: String! { get set }
    var summary: String! { get set }
    var smallBackgroundImage: String? { get }
    var mediumBackgroundImage: String? { get }
    var largeBackgroundImage: String? { get set }
    var smallCoverImage: String? { get }
    var mediumCoverImage: String? { get }
    var largeCoverImage: String? { get set }
    var id: String! { get set }
    var slug: String! { get set }
}
