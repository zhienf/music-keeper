//
//  SceneDelegate.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 18/04/2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let urlContext = connectionOptions.urlContexts.first {
//            handleURL(url: urlContext.url)
            print("I was opened")
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("Link clicked")
        if let urlContext = URLContexts.first {
            handleURL(url: urlContext.url)
        }
    }
    
    func handleURL(url: URL) {
        if url.scheme == "spotify" {
            // Extract the content type and ID from the deep link URL
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                let contentPath = Array(components.path.components(separatedBy: "/").dropFirst())
                if let contentType = contentPath.first, let contentID = contentPath.last {
                     // Perform the desired action in your app based on the content type and ID
                     // For demonstration purposes, we'll print the content type and ID to the console
                     print("Content Type: \(contentType)")
                     print("Content ID: \(contentID)")
                }
            }
        }
    }
    
//    func handleURL(url: URL) {
//        if let scheme = url.scheme, scheme == "spotify", let viewname = url.host {
//            var parameters: [String: String] = [:]
//            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
//                parameters[$0.name] = $0.value
//            }
//
//            switch viewname {
//                case "forgotpassword":
//                    if let email = parameters["email"] {
//                        print("Forgotten password for email \(email)")
//                        let navigationController = window?.rootViewController as? UINavigationController
//                        let forgottenPassWordViewController = storyboard.instantiateViewController(withIdentifier: "forgottenPasswordVC") as! ForgottenPasswordViewController
//                        navigationController?.pushViewController(forgottenPassWordViewController, animated: false)
//                    }
//                    break;
//                default:
//                    print("Unrecognised host passed via URL.")
//            }
//        }
//    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

