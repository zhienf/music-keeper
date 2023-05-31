//
//  LoginAccountViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit
import WebKit

class LoginAccountViewController: UIViewController {

    private let redirectURI = "https://www.google.com"
    private let clientID    = "***REMOVED***"
    private let scope       = "user-top-read,"
                                + "user-read-private,user-read-email,user-read-currently-playing,user-read-recently-played,"
                                +
                                    "user-library-read,"
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
        print("initial url:", url)
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
        // if can't get request token --> auth user
        // get token from the URL, index start from 29
        let index = urlString.index(urlString.startIndex, offsetBy: 29)
        var code = String(urlString.suffix(from: index))
        // if user logs in using facebook, there are unwanted characters
        if code.hasSuffix("#_=_") {
            code = String(code.dropLast(4))
        }

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
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.absoluteString.contains("https://www.google.com/?code=") {
            delegate?.webViewController(self, didRedirectToURL: url)
            decisionHandler(WKNavigationActionPolicy.cancel)
        } else {
            print("allowed url:", url)
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
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
        guard url.absoluteString.contains("https://www.google.com/?code=") else { return }
        
        // NOTE: current implementation is user have to be authorised everytime to get new access token upon launching app, both access & refresh token will be saved, and retrieved when needed.(mostly only access token will be retrieved for now, no need for refreshing) assuming user doesnt spend more than an hour on the app, it should work fine
        print("url:", url)
        authoriseUser(with: url.absoluteString)
        closeCustomWebViewController()
    }
}
