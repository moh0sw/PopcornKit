

import UIKit

extension UIAlertController {
    func show() {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = UIWindowLevelAlert + 1
        window.makeKeyAndVisible()
        if let presentedViewController = window.rootViewController?.presentedViewController where presentedViewController is UIAlertController {return}
        window.rootViewController!.presentViewController(self, animated: true, completion: nil)
    }
}
