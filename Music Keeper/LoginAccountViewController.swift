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
                                + "user-read-private,user-read-email,"
                                + "playlist-modify-public,playlist-modify-private"
                                
    weak var databaseController: DatabaseProtocol?
    
    /*
    Notes:
      - redirectURI encoded website using https://www.urlencoder.org/
      - scope, "user-top-read": required scope for reading user's top artists/tracks data "user-top-read"
      - encodedID = our Basic Auth which is "clientID:clientSecret", base64 encoded using https://www.base64encode.org/
    */

    override func viewDidLoad() {
        super.viewDidLoad()
//        PersistenceManager.saveRefreshToken(refreshToken: "")
//        PersistenceManager.saveAccessToken(accessToken: "")
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
    }
    
    @IBAction func loginAccount(_ sender: Any) {
        guard let url = URL(string: "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(scope)") else {
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
        // get token from the URL: you might need to change your index here
        let index = urlString.index(urlString.startIndex, offsetBy: 29)
        let code = String(urlString.suffix(from: index))
        
        // request for access token
        NetworkManager.shared.authoriseUser(with: code) { result in
            guard let accessToken = result else { return }
            
            self.databaseController?.saveAccessToken(token: accessToken)
            print("accessToken saved:", accessToken)
            
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
        guard currentURL.absoluteString.contains("https://www.google.com/?code=") else { return }
        print("current url:", currentURL)
        authoriseUser(with: currentURL.absoluteString)
        closeSafari()
    }
}
