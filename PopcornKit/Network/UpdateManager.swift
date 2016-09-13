

import Foundation
import Alamofire

/**
 A manager class that automatically looks for new releases from github and presents them to the user.
 */
public final class UpdateManager: NSObject {
    
    /**
     Determines the frequency in which the the version check is performed.
     
     - .Immediately:    Version check performed every time the app is launched.
     - .Daily:          Version check performedonce a day.
     - .Weekly:         Version check performed once a week.
     */
    public enum CheckType: Int {
        /// Version check performed every time the app is launched.
        case Immediately = 0
        /// Version check performed once a day.
        case Daily = 1
        /// Version check performed once a week.
        case Weekly = 7
    }
    
    /// Current version (CFBundleShortVersionString.CFBundleVersion) of running application.
    private let currentApplicationVersion = "\(NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")!).\(NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion")!)"
    
    /// Designated Initialiser.
    public static let sharedManager = UpdateManager()
    
    /// The version that the user does not want installed. If the user has never clicked "Skip this version" this variable will be `nil`, otherwise it will be the last version that the user opted not to install.
    private var skipReleaseVersion: VersionString? {
        get {
            guard let data = NSUserDefaults.standardUserDefaults().dataForKey("skipReleaseVersion") else { return nil }
            return VersionString.unarchive(data)
        } set {
            if let newValue = newValue {
                NSUserDefaults.standardUserDefaults().setObject(newValue.archived(), forKey: "skipReleaseVersion")
            } else {
                NSUserDefaults.standardUserDefaults().removeObjectForKey("skipReleaseVersion")
            }
        }
    }
    
    /// The date of the last time `checkForUpdates:completion:` was called. If version check was never called, `checkForUpdates:completion:` is called.
    private var lastVersionCheckPerformedOnDate: NSDate {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("lastVersionCheckPerformedOnDate") as? NSDate ?? {
                checkForUpdates()
                return self.lastVersionCheckPerformedOnDate
                }()
        } set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "lastVersionCheckPerformedOnDate")
        }
    }
    
    /// Returns the number of days it has been since `checkForUpdates:completion:` has been called.
    private var daysSinceLastVersionCheckDate: Int {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.Day, fromDate: lastVersionCheckPerformedOnDate, toDate: NSDate(), options: [])
        return components.day
    }
    
    /**
     Checks github repository for new releases.
     
     - Parameter sucess: Optional callback indicating the status of the operation.
     */
    public func checkVersion(checkType: CheckType, completion: ((success: Bool) -> Void)? = nil) {
        if checkType == .Immediately {
            checkForUpdates(completion)
        } else {
            if checkType.rawValue <= daysSinceLastVersionCheckDate {
                checkForUpdates(completion)
            }
        }
    }
    
    private func checkForUpdates(completion: ((success: Bool) -> Void)? = nil) {
        lastVersionCheckPerformedOnDate = NSDate()
        let repo = UIDevice.currentDevice().userInterfaceIdiom == .TV ? "PopcornTimeTV" : "PopcornTimeiOS"
        Alamofire.request(.GET, "https://api.github.com/repos/PopcornTimeTV/\(repo)/releases").validate().responseJSON { (response) in
            guard let responseObject = response.result.value as? [String: AnyObject] else { completion?(success: false); return }
            let sortedReleases = responseObject.map({VersionString($1["tag_name"] as! String, $1["published_at"] as! String)!}).sort({$0.0 > $0.1})
            if let latestRelease = sortedReleases.first,
                let currentRelease = sortedReleases.filter({$0.buildNumber == self.currentApplicationVersion}).first
                where latestRelease > currentRelease && self.skipReleaseVersion?.buildNumber != latestRelease.buildNumber {
                let alert = UIAlertController(title: "Update Available", message: "\(latestRelease.releaseType.rawValue.capitalizedString) version \(latestRelease.buildNumber) of Popcorn Time is now available.", preferredStyle: .Alert)
                
                let cydiaInstalled = UIApplication.sharedApplication().canOpenURL(NSURL(string: "cydia://")!)
                if cydiaInstalled {
                    alert.addAction(UIAlertAction(title: "Next time", style: .Default, handler: nil))
                }
                alert.addAction(UIAlertAction(title: "Skip this version", style: .Default, handler: { (action) in
                    self.skipReleaseVersion = latestRelease
                }))
                alert.addAction(UIAlertAction(title: cydiaInstalled ? "Update" : "OK", style: .Default, handler: { _ in
                    if cydiaInstalled {
                        UIApplication.sharedApplication().openURL(NSURL(string: "cydia://package/\(NSBundle.mainBundle().bundleIdentifier!)")!)
                    }
                }))
                completion?(success: true)
                alert.show()
            } else {
                completion?(success: false)
            }
        }
    }
}

internal class VersionString: NSObject, NSCoding {
    
    enum ReleaseType: String {
        case Beta = "beta"
        case Stable = "stable"
    }
    
    let date: NSDate
    let buildNumber: String
    let releaseType: ReleaseType
    
    init?(_ string: String, _ dateString: String) {
        self.buildNumber = string
        self.date = {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return formatter.dateFromString(dateString)!
            }()
        
        let components = string.componentsSeparatedByString(".")
        if let first = components.first, let _ = components[safe: 1], let _ = components[safe: 2] {
            if first == "0" // Beta release. Format will be 0.<major>.<minor>-<patch>.
            {
                self.releaseType = .Beta
            } else // Stable release. Format will be <major>.<minor>.<patch>.
            {
                self.releaseType = .Stable
            }
            return
        }
        return nil
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(date, forKey: "date")
        aCoder.encodeObject(buildNumber, forKey: "buildNumber")
        aCoder.encodeObject(releaseType.rawValue, forKey: "releaseType")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let date = aDecoder.decodeObjectForKey("date") as? NSDate,
            let buildNumber = aDecoder.decodeObjectForKey("buildNumber") as? String,
            let releaseTypeRawValue = aDecoder.decodeObjectForKey("releaseType") as? String,
            let releaseType = ReleaseType(rawValue: releaseTypeRawValue) else { return nil }
        self.date = date
        self.buildNumber = buildNumber
        self.releaseType = releaseType
    }
    
    func archived() -> NSData {
        return NSKeyedArchiver.archivedDataWithRootObject(self)
    }
    
    class func unarchive(data: NSData) -> VersionString? {
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? VersionString
    }
}

internal func >(lhs: VersionString, rhs: VersionString) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedDescending
}

internal func <(lhs: VersionString, rhs: VersionString) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedAscending
}

internal func ==(lhs: VersionString, rhs: VersionString) -> Bool {
    return lhs.date.compare(rhs.date) == .OrderedSame
}

extension CollectionType {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
