

import Foundation
import ObjectMapper

/// Generic media protocol.
public protocol Media: Mappable {
    var title: String { get }
    var id: String { get }
    var tmdbId: Int? { get set }
    var slug: String { get }
    
    var summary: String { get }
    
    var smallBackgroundImage: String? { get }
    var mediumBackgroundImage: String? { get }
    var largeBackgroundImage: String? { get set }
    var smallCoverImage: String? { get }
    var mediumCoverImage: String? { get }
    var largeCoverImage: String? { get set }
    
    /// Will be `nil` is Media is Show.
    var subtitles: [Subtitle]! { get set }
    /// Will be `nil` is Media is Show.
    var currentSubtitle: Subtitle? { get set }
    
    /// Will be `nil` is Media is Show.
    var torrents: [Torrent]! { get set }
    /// Will be `nil` is Media is Show.
    var currentTorrent: Torrent? { get set }
}

// MARK: - Optional vars

extension Media {
    public var subtitles: [Subtitle]! { get { return nil } set {} }
    public var currentSubtitle: Subtitle? { get { return nil } set {} }
    
    public var torrents: [Torrent]! { get { return nil } set {} }
    public var currentTorrent: Torrent? { get { return nil } set {} }
    
    public var smallCoverImage: String? { return nil }
    public var mediumCoverImage: String? { return nil }
    public var largeCoverImage: String? { get{ return nil } set {} }
}

extension String {
    public var isAmazonUrl: Bool {
        return contains("https://images-na.ssl-images-amazon.com/images/")
    }
}

open class StringTransform: TransformType {
    public typealias Object = String
    public typealias JSON = Int
    
    public init() {}
    
    open func transformFromJSON(_ value: Any?) -> String? {
        if let int = value as? Int {
            return String(int)
        }
        
        return nil
    }
    
    open func transformToJSON(_ value: String?) -> Int? {
        if let string = value {
            return Int(string)
        }
        return nil
    }
}
