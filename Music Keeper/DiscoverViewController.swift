//
//  DiscoverViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 09/05/2023.
//

import UIKit

class DiscoverViewController: UIViewController {

    @IBAction func randomButton(_ sender: Any) {
//        if let spotifyURL = URL(string: "spotify:track:0OUb9GCxls0erHrS98Htv1") {
//            print("url:",spotifyURL)
//            if UIApplication.shared.canOpenURL(spotifyURL) {
//                print("can open")
//                UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
//            } else {
//                // Spotify app is not installed, handle this case if needed
//                print("cannot")
//                return
//            }
//        }
        
        if let url = URL(string: "spotify://track/6QElYAt0RHossldXx3Udv9") {
            if UIApplication.shared.canOpenURL(url) {
                print("can open")
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                print("cannot")
                // Handle case when Spotify app is not installed
            }
        }
        
//        if let spotifyURL = URL(string: "https://open.spotify.com/album/0OUb9GCxls0erHrS98Htv1") {
//            if UIApplication.shared.canOpenURL(spotifyURL) {
//                print("can open")
//                UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
//            }
//        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
