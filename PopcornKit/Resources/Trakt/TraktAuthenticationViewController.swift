

import UIKit

public class TraktAuthenticationViewController: UIViewController {
    @IBOutlet weak var qrImageView: UIImageView!
	@IBOutlet weak var codeLabel: UILabel!
	@IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

	var intervalTimer: Timer?
    var deviceCode: String?
    var expiresIn: Date?

	public override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(true)
		getNewCode()
		qrImageView.image = UIImage(named: "TraktQRCode.png", in: TraktAuthenticationViewController.bundle, compatibleWith: nil)
	}

	public override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		intervalTimer?.invalidate()
        intervalTimer = nil
	}

	private func getNewCode() {
		activityIndicatorView.startAnimating()
        TraktManager.shared.generateCode { [weak self] (displayCode, deviceCode, expires, interval, error) in
            guard let displayCode = displayCode, let deviceCode = deviceCode, let expires = expires, let interval = interval, error == nil else {return}
            self?.codeLabel.text = displayCode
            self?.expiresIn = expires
            self?.deviceCode = deviceCode
            self?.intervalTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self?.poll(timer:)), userInfo: nil, repeats: true)
        }
	}

    static var bundle: Bundle? {
        return Bundle(for: TraktAuthenticationViewController.self)
    }

	public func poll(timer: Timer) {
        if let expiresIn = expiresIn, expiresIn < Date() {
            timer.invalidate()
            getNewCode()
        } else if let deviceCode = deviceCode {
            DispatchQueue.global(qos: .default).async { [weak self] in
                do {
                    let credential = try OAuthCredential(Trakt.base + Trakt.auth + Trakt.device + Trakt.token, parameters: ["code": deviceCode], clientID: Trakt.apiKey, clientSecret: Trakt.apiSecret, useBasicAuthentication: false)
                    credential.store(withIdentifier: "trakt")
                    self?.dismiss(animated: true, completion: nil)
                    TraktManager.shared.delegate?.AuthenticationDidSucceed()
                } catch { }
            }
        }
	}
}
