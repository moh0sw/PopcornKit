

import Foundation
import ObjectMapper

public struct Subtitle: Mappable {
    var language: String!
    var link: String!
    var ISO639: String!
    
    public init?(_ map: Map) {
        guard map["LanguageName"].currentValue != nil && map["SubDownloadLink"].currentValue != nil && map["ISO639"].currentValue != nil else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.language <- map["LanguageName"]
        self.link <- map["SubDownloadLink"]
        self.ISO639 <- map["ISO639"]
    }
    
}
