

import Foundation
import ObjectMapper

public protocol Media: Mappable {
    var title: String! { get set }
    var summary: String? { get set }
    var smallBackgroundImage: String? { get }
    var mediumBackgroundImage: String? { get }
    var largeBackgroundImage: String? { get set }
    var smallCoverImage: String? { get }
    var mediumCoverImage: String? { get }
    var largeCoverImage: String? { get set }
    var id: String! { get set }
    var slug: String! { get set }
    
    var subtitles: [Subtitle]? { get set }
    var currentSubtitle: Subtitle? { get set }
}

// MARK: - Optional vars

extension Media {
    public var subtitles: [Subtitle]? {
        get { return nil} set {}
    }
    public var currentSubtitle: Subtitle? {
        get { return nil} set {}
    }
    
    public var smallCoverImage: String? { return nil }
    public var mediumCoverImage: String? { return nil }
    public var largeCoverImage: String? { get{return nil} set{} }
}
