

import Foundation

protocol Media {
    var title: String! { get set }
    var summary: String! { get set }
    var torrents: [Torrent]! { get set }
    var currentTorrent: Torrent! { get set }
    var subtitles: [Subtitle]? { get set }
    var currentSubtitle: Subtitle? { get set }
    var smallBackgroundImage: String? { get }
    var mediumBackgroundImage: String? { get }
    var largeBackgroundImage: String? { get set }
    var smallCoverImage: String? { get }
    var mediumCoverImage: String? { get }
    var largeCoverImage: String? { get set }
    var id: String! { get set }
    var slug: String! { get set }
}
