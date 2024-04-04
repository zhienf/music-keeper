//
//  LoginAccountViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//
// References:
// 1) https://developer.spotify.com/documentation/web-api/tutorials/code-flow
// 2) https://developer.apple.com/documentation/webkit/wkwebview
// 3) https://stackoverflow.com/questions/47587556/how-to-know-if-a-wkwebview-is-redirecting-due-to-a-user-interaction
// 4) https://www.hackingwithswift.com/read/4/2/creating-a-simple-browser-with-wkwebview
// 5) https://youtu.be/uyqPBNJ33jw (How To Use Spotify's API In Swift)

import UIKit
import WebKit

/**
 A view controller that request authorization from the user, so our app can access to the Spotify resources in behalf that user.

 This class is a subclass of UIViewController.

 Usage:
 1. Request authorization from the user to get access token for subsequent Spotify API calls.
 2. Displays a custom web view controller which prompts user to log in to their Spotify account.
 */
class LoginAccountViewController: UIViewController {

    /*
    Notes:
      - redirectURI encoded website using https://www.urlencoder.org/
      - scope, "user-top-read": required scope for reading user's top artists/tracks data "user-top-read"
      - encodedID = our Basic Auth which is "clientID:clientSecret", base64 encoded using https://www.base64encode.org/
    */
    private let redirectURI = "https://www.google.com"
    private let clientID    = "b8a60d894569482aa55897a613352a39"
    private let scope       = "user-top-read,"
                                + "user-read-private,user-read-email,user-read-currently-playing,user-read-recently-played,"
                                +
                                    "user-library-read,"
                                + "playlist-modify-public,playlist-modify-private,playlist-read-private,playlist-read-collaborative"
    
    // core data to store access token
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
    }
    
    @IBAction func loginAccount(_ sender: Any) {
        /**
         Displays a custom web view with the url provided to authorise user.
         */
        guard let url = URL(string: "https://accounts.spotify.com/authorize?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(scope)") else {
            print("invalid url")
            return
        }
        presentCustomWebViewController(with: url)
    }
    
    private func presentCustomWebViewController(with url: URL) {
        let customWebVC = CustomWebViewController(url: url)
        customWebVC.delegate = self
        present(customWebVC, animated: true)
    }
    
    private func closeCustomWebViewController() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: false)
    }
    
    private func authoriseUser(with urlString: String) {
        // get token from the URL, index start from 29 (start after the redirect url)
        let index = urlString.index(urlString.startIndex, offsetBy: 29)
        var code = String(urlString.suffix(from: index))
        
        // if user logs in using facebook, remove unwanted characters from code retrieved from url
        if code.hasSuffix("#_=_") {
            code = String(code.dropLast(4))
        }

        // request for access token from Spotify API
        NetworkManager.shared.authoriseUser(with: code) { result in
            guard result != nil else { return }

            DispatchQueue.main.async {
                // Get the tab bar controller
                guard let tabBarController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController else { return }

                // Segues to tab bar controller
                self.navigationController?.pushViewController(tabBarController, animated: true)
            }
        }
    }
}

// MARK: - CustomWebViewController

class CustomWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private let url: URL
    weak var delegate: CustomWebViewControllerDelegate?
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        /**
         Checks if the redirected url matches the value of redirect uri supplied when requesting the authorization code, if so exchange the authorization code for an Access Token.
         */
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.absoluteString.contains("https://www.google.com/?code=") {
            delegate?.webViewController(self, didRedirectToURL: url)
            decisionHandler(WKNavigationActionPolicy.cancel) // cancel the redirection
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        /**
         Displays keyboard when a text field is selected.
         */
        let alertController = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alertController.textFields?.first?.text)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - CustomWebViewControllerDelegate

protocol CustomWebViewControllerDelegate: AnyObject {
    func webViewController(_ webViewController: CustomWebViewController, didRedirectToURL url: URL)
}

// MARK: - LoginAccountViewController+CustomWebViewControllerDelegate

extension LoginAccountViewController: CustomWebViewControllerDelegate {
    func webViewController(_ webViewController: CustomWebViewController, didRedirectToURL url: URL) {
        /**
         Request for access token when user is authorised, and when the link is redirected to the redirect uri.
         */
        guard url.absoluteString.contains("https://www.google.com/?code=") else { return }
        
        // NOTE: current implementation is user have to be authorised everytime to get new access token upon launching app, both access & refresh token will be saved, and retrieved when needed.(mostly only access token will be retrieved for now, no need for refreshing) assuming user doesnt spend more than an hour on the app, it should work fine
        authoriseUser(with: url.absoluteString)
        closeCustomWebViewController()
    }
}
