

import AlamofireXMLRPC
import Alamofire

public class SubtitlesManager {
    
    /// Creates new instance of SubtitlesManager class
    public static let sharedManager = SubtitlesManager()
    
    // MARK: - Private Variables.
    
    private let baseURL = "http://api.opensubtitles.org:80/xml-rpc"
    private let secureBaseURL = "https://api.opensubtitles.org:443/xml-rpc"
    private let userAgent = "Popcorn Time v1"
    private var token: String?
    var protectionSpace: NSURLProtectionSpace {
        let url = NSURL(string: secureBaseURL)!
        return NSURLProtectionSpace(host: url.host!, port: url.port!.integerValue, protocol: url.scheme, realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
    }
    
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:       The show episode.
     - Parameter imdbId:        The Imdb identification code of the episode or movie.
     - Parameter limit:         The limit of subtitles to fetch as a `String`. Defaults to 300.
     
     - Parameter completion:    Completion handler called with array of subtitles and an optional error.
     */
    public func search(episode: Episode? = nil, imdbId: String? = nil, limit: String = "300", completion:(subtitles: [Subtitle], error: NSError?) -> Void) {
        var params: XMLRPCStructure = ["sublanguageid": "all"]
        if let imdbId = imdbId {
            params["imdbid"] = imdbId.stringByReplacingOccurrencesOfString("tt", withString: "")
        } else if let episode = episode {
            params["query"] = episode.title
            params["season"] = String(episode.season)
            params["episode"] = String(episode.episode)
        }
        let array: XMLRPCArray = [params]
        let limit: XMLRPCStructure = ["limit": limit]
        let queue = dispatch_queue_create("com.popcorn-time.response.queue", DISPATCH_QUEUE_CONCURRENT)
        AlamofireXMLRPC.request(secureBaseURL, methodName: "SearchSubtitles", parameters: [token!, array, limit], headers: ["User-Agent": userAgent]).validate().response(queue: queue, responseSerializer: Request.XMLRPCResponseSerializer(), completionHandler: { response in
            guard let value = response.result.value,
                let status = value[0]["status"].string?.componentsSeparatedByString(" ").first,
                let data = value[0]["data"].array
                where response.result.isSuccess && status == "200" else {dispatch_async(dispatch_get_main_queue(), {completion(subtitles: [Subtitle](), error: response.result.error)}); return}
            var subtitles = [Subtitle]()
            for info in data {
                guard let languageName = info["LanguageName"].string,
                    let subDownloadLink = info["SubDownloadLink"].string,
                    let ISO639 = info["ISO639"].string
                    where !subtitles.contains({$0.language == languageName}) else { continue }
                subtitles.append(Subtitle(language: languageName, link: subDownloadLink, ISO639: ISO639))
            }
            subtitles.sortInPlace({ $0.language < $1.language })
            dispatch_async(dispatch_get_main_queue(), {completion(subtitles: subtitles, error: nil)})
        })
    }
    
    /**
     Login to OpenSubtitles API. Login is required to use the API.
     
     - Parameter completion:    Optional completion handler called when request is sucessfull.
     - Parameter error:         Optional error completion handler called when request fails or username/password is incorrect.
     */
    public func login(completion:(() -> Void)?, error:((error: NSError) -> Void)? = nil) {
        var username = ""
        var password = ""
        if let credential = NSURLCredentialStorage.sharedCredentialStorage().credentialsForProtectionSpace(protectionSpace)?.values.first {
            username = credential.user!
            password = credential.password!
        }
        AlamofireXMLRPC.request(secureBaseURL, methodName: "LogIn", parameters: [username, password, "en", userAgent]).validate().responseXMLRPC { response in
            guard let value = response.result.value,
                let status = value[0]["status"].string?.componentsSeparatedByString(" ").first
                where response.result.isSuccess && status == "200" else {
                    let statusError = response.result.error ?? NSError(domain: "com.AlamofireXMLRPC.error", code: -403, userInfo: [NSLocalizedDescriptionKey: "Username or password is incorrect."])
                    error?(error: statusError)
                    return
            }
            self.token = value[0]["token"].string
            completion?()
        }
    }
}
