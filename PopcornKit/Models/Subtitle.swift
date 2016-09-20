

import Foundation
import ObjectMapper

public struct Subtitle: Mappable {
    public var language: String!
    public var link: String!
    public var ISO639: String!
    
    public init(language: String, link: String, ISO639: String) {
        self.language = language
        self.link = link
        self.ISO639 = ISO639
    }
    
    public init?(map: Map) {
        guard map["LanguageName"].currentValue != nil && map["SubDownloadLink"].currentValue != nil && map["ISO639"].currentValue != nil else {return nil}
    }
    
    public mutating func mapping(map: Map) {
        self.language <- map["LanguageName"]
        self.link <- map["SubDownloadLink"]
        self.ISO639 <- map["ISO639"]
    }
    
}
