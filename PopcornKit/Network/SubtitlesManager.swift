

import Alamofire
import AlamofireXMLRPC

open class SubtitlesManager: NetworkManager {
    
    /// Creates new instance of SubtitlesManager class
    open static let shared = SubtitlesManager()
    
    // MARK: - Private Variables.
    
    fileprivate let baseURL = "http://api.opensubtitles.org:80/xml-rpc"
    fileprivate let secureBaseURL = "https://api.opensubtitles.org:443/xml-rpc"
    fileprivate let userAgent = "Popcorn Time v1"
    fileprivate var token: String?
    var protectionSpace: URLProtectionSpace {
        let url = URL(string: secureBaseURL)!
        return URLProtectionSpace(host: url.host!, port: (url as NSURL).port!.intValue, protocol: url.scheme, realm: nil, authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
    }
    
    /**
     Load subtitles from API. Use episode or ImdbId not both. Using ImdbId rewards better results.
     
     - Parameter episode:       The show episode.
     - Parameter imdbId:        The Imdb identification code of the episode or movie.
     - Parameter limit:         The limit of subtitles to fetch as a `String`. Defaults to 300.
     
     - Parameter completion:    Completion handler called with array of subtitles and an optional error.
     */
    open func search(_ episode: Episode? = nil, imdbId: String? = nil, limit: String = "300", completion:@escaping (_ subtitles: [Subtitle], _ error: NSError?) -> Void) {
        var params = ["sublanguageid": "all"]
        if let imdbId = imdbId {
            params["imdbid"] = imdbId.replacingOccurrences(of: "tt", with: "")
        } else if let episode = episode {
            params["query"] = episode.title
            params["season"] = String(episode.season)
            params["episode"] = String(episode.episode)
        }
        let limit = ["limit": limit]
        let queue = DispatchQueue(label: "com.popcorn-time.response.queue", attributes: DispatchQueue.Attributes.concurrent)
        self.manager.requestXMLRPC(secureBaseURL, methodName: "SearchSubtitles", parameters: [token!, [params], limit], headers: ["User-Agent": userAgent]).validate().responseXMLRPC(queue: queue, completionHandler: { response in
            guard let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first,
                let data = value[0]["data"].array
                , response.result.isSuccess && status == "200" else { DispatchQueue.main.async(execute: {completion([Subtitle](), response.result.error as NSError?)}); return}
            var subtitles = [Subtitle]()
            for info in data {
                guard let languageName = info["LanguageName"].string,
                    let subDownloadLink = info["SubDownloadLink"].string,
                    let ISO639 = info["ISO639"].string
                    , !subtitles.contains(where: {$0.language == languageName}) else { continue }
                subtitles.append(Subtitle(language: languageName, link: subDownloadLink, ISO639: ISO639))
            }
            subtitles.sort(by: { $0.language < $1.language })
            DispatchQueue.main.async(execute: { completion(subtitles, nil) })
        })
    }
    
    /**
     Login to OpenSubtitles API. Login is required to use the API.
     
     - Parameter completion:    Optional completion handler called when request is sucessfull.
     - Parameter error:         Optional error completion handler called when request fails or username/password is incorrect.
     */
    open func login(_ completion: (() -> Void)?, error: ((_ error: NSError) -> Void)? = nil) {
        var username = ""
        var password = ""
        if let credential = URLCredentialStorage.shared.credentials(for: protectionSpace)?.values.first {
            username = credential.user!
            password = credential.password!
        }
        self.manager.requestXMLRPC(secureBaseURL, methodName: "LogIn", parameters: [username, password, "en", userAgent]).validate().responseXMLRPC { response in
            guard let value = response.result.value,
                let status = value[0]["status"].string?.components(separatedBy: " ").first
                , response.result.isSuccess && status == "200" else {
                    let statusError = response.result.error ?? NSError(domain: "com.AlamofireXMLRPC.error", code: -403, userInfo: [NSLocalizedDescriptionKey: "Username or password is incorrect."])
                    error?(statusError as NSError)
                    return
            }
            self.token = value[0]["token"].string
            completion?()
        }
    }
}
