

import Foundation
import ObjectMapper

public enum Health {
    case bad
    case medium
    case good
    case excellent
    case unknown
    
    func color() -> UIColor {
        switch self {
        case .bad:
            return UIColor(red: 212.0/255.0, green: 14.0/255.0, blue: 0.0, alpha: 1.0)
        case .medium:
            return UIColor(red: 212.0/255.0, green: 120.0/255.0, blue: 0.0, alpha: 1.0)
        case .good:
            return UIColor(red: 201.0/255.0, green: 212.0/255.0, blue: 0.0, alpha: 1.0)
        case .excellent:
            return UIColor(red: 90.0/255.0, green: 186.0/255.0, blue: 0.0, alpha: 1.0)
        case .unknown:
            return UIColor(red: 105.0/255.0, green: 105.0/255.0, blue: 105.0, alpha: 1.0)
        }
    }
}

public struct Torrent: Mappable, Equatable, Comparable {
    
    fileprivate var trackers: String {
        return Trackers.map({$0}).joined(separator: "&tr=")
    }
    public var magnet: String {
        return "magnet:?xt=urn:btih:\(self.hash)&tr=" + self.trackers
    }
    public lazy var health: Health = {
        guard let seeds = self.seeds, let peers = self.peers else {return .unknown}
        
        // First calculate the seed/peer ratio
        let ratio = peers > 0 ? (seeds / peers) : seeds
        
        // Normalize the data. Convert each to a percentage
        // Ratio: Anything above a ratio of 5 is good
        let normalizedRatio = min(ratio / 5 * 100, 100)
        // Seeds: Anything above 30 seeds is good
        let normalizedSeeds = min(seeds / 30 * 100, 100)
        
        // Weight the above metrics differently
        // Ratio is weighted 60% whilst seeders is 40%
        let weightedRatio = Double(normalizedRatio) * 0.6
        let weightedSeeds = Double(normalizedSeeds) * 0.4
        let weightedTotal = weightedRatio + weightedSeeds
        
        // Scale from [0, 100] to [0, 3]. Drops the decimal places
        var scaledTotal = ((weightedTotal * 3.0) / 100.0)// | 0.0
        if scaledTotal < 0 { scaledTotal = 0 }
        
        switch floor(scaledTotal) {
        case 0:
            return .bad
        case 1:
            return .medium
        case 2:
            return .good
        case 3:
            return .excellent
        default:
            return .unknown
        }
    }()
    
    public var url: String!
    public var hash: String!
    public var quality: String!
    public var seeds: Int!
    public var peers: Int!
    public var size: String?
    public var sizeBytes: Int?
    
    public init?(map: Map) {
        guard map["url"].currentValue != nil && (map["seeds"].currentValue != nil || map["seed"].currentValue != nil) && (map["peers"].currentValue != nil || map["peer"].currentValue != nil) else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.url <- map["url"]
        self.hash = url.contains("https://") ? url : url.sliceFrom("magnet:?xt=urn:btih:", to: url.contains("&dn=") ? "&dn=" : "")
        self.seeds <- map["seeds"]; seeds = seeds ?? map["seed"].currentValue as? Int ?? 0
        self.peers <- map["peers"]; peers = peers ?? map["peer"].currentValue as? Int ?? 0
        self.size <- map["filesize"]
        self.sizeBytes <- map["size"]
    }
}

public func >(lhs: Torrent, rhs: Torrent) -> Bool {
    if let lhsSize = lhs.quality, let rhsSize = rhs.quality {
        if lhsSize.characters.count == 2  && rhsSize.characters.count > 2 // 3D
        {
            return true
        } else if lhsSize.characters.count == 5 && rhsSize.characters.count < 5 && rhsSize.characters.count > 2 // 1080p
        {
            return true
        } else if lhsSize.characters.count == 4 && rhsSize.characters.count == 4 // 720p and 480p
        {
            return lhsSize > rhsSize
        }
    }
    return false
}

public func <(lhs: Torrent, rhs: Torrent) -> Bool {
    if let lhsSize = lhs.quality, let rhsSize = rhs.quality {
        if rhsSize.characters.count == 2  && lhsSize.characters.count > 2 // 3D
        {
            return true
        } else if rhsSize.characters.count == 5 && lhsSize.characters.count < 5 && lhsSize.characters.count > 2 // 1080p
        {
            return true
        } else if rhsSize.characters.count == 4 && lhsSize.characters.count == 4 // 720p and 480p
        {
            return lhsSize < rhsSize
        }
    }
    return false
}

public func == (lhs: Torrent, rhs: Torrent) -> Bool {
    return lhs.hash == rhs.hash
}
