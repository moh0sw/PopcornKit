

extension String {
    func slice(from start: String, to: String) -> String? {
        return (range(of: start)?.upperBound).flatMap { sInd in
            let eInd = range(of: to, range: sInd..<endIndex)
            if eInd != nil {
                return (eInd?.lowerBound).map { eInd in
                    return substring(with: sInd..<eInd)
                }
            }
            return substring(with: sInd..<endIndex)
        }
    }
    var slugged: String {
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
        
        let cocoaString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(cocoaString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(cocoaString, nil, kCFStringTransformStripCombiningMarks, false)
        CFStringLowercase(cocoaString, .none)
        
        return String(cocoaString)
            .components(separatedBy: allowedCharacters.inverted)
            .filter { $0 != "" }
            .joined(separator: "-")
    }
    
    var cleaned: String {
        return replacingOccurrences(of: "\"", with: "")
    }
    
    static func random(_ length: Int) -> String {
        let alphabet = "-_1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map { _ -> Character in
            return alphabet[alphabet.characters.index(alphabet.startIndex, offsetBy: Int(arc4random_uniform(UInt32(alphabet.characters.count))))]
            })
    }
    
    var queryString: [String: String] {
        var queryStringDictionary = [String: String]()
        let urlComponents = components(separatedBy: "&")
        for keyValuePair in urlComponents {
            let pairComponents = keyValuePair.components(separatedBy: "=")
            let key = pairComponents.first?.removingPercentEncoding
            let value = pairComponents.last?.removingPercentEncoding
            queryStringDictionary[key!] = value!
        }
        return queryStringDictionary
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
