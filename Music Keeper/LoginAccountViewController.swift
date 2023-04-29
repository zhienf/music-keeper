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
        
        databaseController.save
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
        print("token:", code)
        
        NetworkManager.shared.authoriseUser(with: code) { result in
            guard let accessToken = result else { return }
            print("accessToken2:", accessToken)
            
            DispatchQueue.main.async {
//                guard let overviewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: OverviewViewController.reuseID) as? OverviewViewController else { return }
//                overviewVC.token = accessToken
//                self.navigationController?.pushViewController(overviewVC, animated: true)
//                self.performSegue(withIdentifier: "showOverviewSegue", sender: accessToken)
                
                // Get the tab bar controller
                guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController else { return }
                print("tab bar:", tabBarController)
                // Pass the data to the overview view controller
                print("vcontrollers:",tabBarController.viewControllers)
                print(tabBarController.viewControllers?.first)
                if let overviewVC = tabBarController.viewControllers?.first as? OverviewViewController {
                    print("overview controller:",overviewVC)
                    overviewVC.token = accessToken
                    print("coontroller token:",overviewVC.token)
                    
                }

                // Show the tab bar controller
                self.navigationController?.pushViewController(tabBarController, animated: true)
            }
        }
    }
    
    private func closeSafari() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: false)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showOverviewSegue" {
//            let accessToken = sender as? String
//            let controller = segue.destination as? Tab
//            overviewVC?.token = accessToken
//            print("overviewVC:",overviewVC)
//            print("overviewVC token:", overviewVC?.token)
//        }
//    }
}

// MARK: - SFSafariViewControllerDelegate

extension LoginAccountViewController: SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
        let currentURL = URL.absoluteURL
        guard currentURL.absoluteString.contains("https://www.google.com/?code=") else { return }
        print("current url:", currentURL)
        authoriseUser(with: currentURL.absoluteString)
        closeSafari()
//        let currentURL = URL.absoluteString
//
//        if currentURL.contains("\(baseURL.colin)?code=")
//        {
//            closeSFSafari()
//            showLoadingView()
//
//            if PersistenceManager.retrieveRefreshToken() == "" {
//                self.authorizeFirstTimeUser(with: currentURL)
//            } else {
//
//                NetworkManager.shared.getRefreshToken() { results in
//                    guard let accessToken = results else {
//                        self.presentSSAlertOnMainThread(title: "Sorry", message: Message.authorization, isPlaylistAlert: false)
//                        return
//                    }
//
//                    DispatchQueue.main.async {
//                        self.dismissLoadingView()
//                        let homeVC = HomeViewController()
//                        homeVC.OAuthtoken = accessToken
//                        self.navigationController?.pushViewController(homeVC, animated: true)
//                    }
//                }
//            }
//        }
    }
}
