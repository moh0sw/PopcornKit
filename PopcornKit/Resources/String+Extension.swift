

import Foundation

extension String {
    func sliceFrom(start: String, to: String) -> String? {
        return (rangeOfString(start)?.endIndex).flatMap { sInd in
            let eInd = rangeOfString(to, range: sInd..<endIndex)
            if eInd != nil {
                return (eInd?.startIndex).map { eInd in
                    return substringWithRange(sInd..<eInd)
                }
            }
            return substringWithRange(sInd..<endIndex)
        }
    }
    var slugged: String {
        let allowedCharacters = NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        
        let cocoaString = NSMutableString(string: self) as CFMutableStringRef
        CFStringTransform(cocoaString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(cocoaString, nil, kCFStringTransformStripCombiningMarks, false)
        CFStringLowercase(cocoaString, .None)
        
        return String(cocoaString)
            .componentsSeparatedByCharactersInSet(allowedCharacters.invertedSet)
            .filter { $0 != "" }
            .joinWithSeparator("-")
    }
}

public let Trackers = [
    "udp://tracker.opentrackr.org:1337/announce",
    "udp://glotorrents.pw:6969/announce",
    "udp://torrent.gresille.org:80/announce",
    "udp://tracker.openbittorrent.com:80",
    "udp://tracker.coppersurfer.tk:6969",
    "udp://tracker.leechers-paradise.org:6969",
    "udp://p4p.arenabg.ch:1337",
    "udp://tracker.internetwarriors.net:1337",
    "udp://open.demonii.com:80",
    "udp://tracker.coppersurfer.tk:80",
    "udp://tracker.leechers-paradise.org:6969",
    "udp://exodus.desync.com:6969"
]
