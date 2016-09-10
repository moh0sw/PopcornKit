

import Foundation
import ObjectMapper
import Alamofire

public enum Health {
    case Bad
    case Medium
    case Good
    case Excellent
    case Unknown
    
    func color() -> UIColor {
        switch self {
        case .Bad:
            return UIColor(red: 212.0/255.0, green: 14.0/255.0, blue: 0.0, alpha: 1.0)
        case .Medium:
            return UIColor(red: 212.0/255.0, green: 120.0/255.0, blue: 0.0, alpha: 1.0)
        case .Good:
            return UIColor(red: 201.0/255.0, green: 212.0/255.0, blue: 0.0, alpha: 1.0)
        case .Excellent:
            return UIColor(red: 90.0/255.0, green: 186.0/255.0, blue: 0.0, alpha: 1.0)
        case .Unknown:
            return UIColor(red: 105.0/255.0, green: 105.0/255.0, blue: 105.0, alpha: 1.0)
        }
    }
}

public struct Torrent: Mappable, Equatable, Comparable {
    
    private var trackers: String {
        return Trackers.map({$0}).joinWithSeparator("&tr=")
    }
    public var magnet: String {
        return "magnet:?xt=urn:btih:\(self.hash)&tr=" + self.trackers
    }
    public lazy var health: Health = {
        guard let seeds = self.seeds, let peers = self.peers else {return .Unknown}
        
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
            return .Bad
        case 1:
            return .Medium
        case 2:
            return .Good
        case 3:
            return .Excellent
        default:
            return .Unknown
        }
    }()
    
    public var url: String!
    public var hash: String!
    public var quality: String!
    public var seeds: Int!
    public var peers: Int!
    public var size: String!
    public var sizeBytes: Int!
    
    public init?(_ map: Map) {
        guard let quality = map.JSONDictionary.keys.first where quality != "0" && map["quality.url"].currentValue != nil && map["quality.seeds"].currentValue != nil && map["quality.seeds"].currentValue != nil && map["quality.filesize"].currentValue != nil && map["quality.size"].currentValue != nil else {return nil}
        self.quality = quality
    }
    
    public mutating func mapping(map: Map) {
        self.url <- map["quality.url"]
        self.hash = url.containsString("https://") ? url : url.sliceFrom("magnet:?xt=urn:btih:", to: url.containsString("&dn=") ? "&dn=" : "")
        self.seeds <- map["quality.seeds"]
        self.peers <- map["quality.peers"]
        self.size <- map["quality.filesize"]
        self.sizeBytes <- map["quality.size"]
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

public func downloadTorrentFile(path: String, completion: (url: String?, error: NSError?) -> Void) {
    var finalPath: NSURL!
    Alamofire.download(.GET, path, destination: { (temporaryURL, response) -> NSURL in
        finalPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(response.suggestedFilename!)
        if NSFileManager.defaultManager().fileExistsAtPath(finalPath.relativePath!) {
            try! NSFileManager.defaultManager().removeItemAtPath(finalPath.relativePath!)
        }
        return finalPath
    }).validate().response { (_, _, _, error) in
        if let error = error {
            print(error)
            completion(url: nil, error: error)
            return
        }
        completion(url: finalPath.relativePath!, error: nil)
    }
}