//
//  LoginAccountViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit
import SafariServices

class LoginAccountViewController: UIViewController {

    private let redirectURI = "https://www.google.com"
    private let clientID    = "***REMOVED***"
    private let scope       = "user-top-read,"
                                + "user-read-private,user-read-email,user-read-currently-playing,user-read-recently-played,"
                                + "playlist-modify-public,playlist-modify-private,playlist-read-private,playlist-read-collaborative"
                                
    weak var databaseController: DatabaseProtocol?
    
    /*
    Notes:
      - redirectURI encoded website using https://www.urlencoder.org/
      - scope, "user-top-read": required scope for reading user's top artists/tracks data "user-top-read"
      - encodedID = our Basic Auth which is "clientID:clientSecret", base64 encoded using https://www.base64encode.org/
    */

    override func viewDidLoad() {
        super.viewDidLoad()
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
    }
    
    @IBAction func loginAccount(_ sender: Any) {
        guard let url = URL(string: "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(scope)") else {
            print("invalid url")
            return
        }
        presentSafariVC(with: url)
    }
    
    private func presentSafariVC(with url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor  = .systemGreen
        safariVC.preferredBarTintColor      = .black
        safariVC.delegate                   = self
        present(safariVC, animated: true)
    }
    
    private func authoriseUser(with urlString: String) {
        // if can't get request token --> auth user
        // get token from the URL, index start from 29
        let index = urlString.index(urlString.startIndex, offsetBy: 29)
        let code = String(urlString.suffix(from: index))

        // request for access token
        NetworkManager.shared.authoriseUser(with: code) { result in
            guard let accessToken = result else { return }

            print("authorised, accessToken:", accessToken)

            DispatchQueue.main.async {
                // Get the tab bar controller
                guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController else { return }

                // Show the tab bar controller
                self.navigationController?.pushViewController(tabBarController, animated: true)
            }
        }
    }
    
    private func closeSafari() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: false)
    }
}

// MARK: - SFSafariViewControllerDelegate

extension LoginAccountViewController: SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        let currentURL = URL.absoluteURL
        print("current url:", currentURL)
        guard currentURL.absoluteString.contains("https://www.google.com/?code=") else { return }
        print("current url:", currentURL)
        
        // NOTE: current implementation is user have to be authorised everytime to get new access token upon launching app, both access & refresh token will be saved, and retrieved when needed.(mostly only access token will be retrieved for now, no need for refreshing) assuming user doesnt spend more than an hour on the app, it should work fine
        authoriseUser(with: currentURL.absoluteString)
        closeSafari()
    }
}
