//
//  GeneratePlaylistViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 17/05/2023.
//

import UIKit

class GeneratePlaylistViewController: UIViewController {

    @IBOutlet weak var artistInput: UITextField!
    
    @IBOutlet weak var playlistNameInput: UITextField!
    
    @IBAction func generatePlaylist(_ sender: Any) {
//        artistInput.text =
//        performSegue(withIdentifier: "showPlaylistGenerated", sender: sender)
    }
    
    weak var databaseController: DatabaseProtocol?
    var token: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("gen playlist token:", token!)
        print("gen playlist refresh token:", refreshToken)
        
//        fetchSearchItem()
    }
    
    private func fetchSearchItem() {
        guard let token = token else { return }
        let query = "flume"
        NetworkManager.shared.searchArtistItems(with: token, query: query) { artistResult in
            guard let artistResult = artistResult else { return }

//            let artist = artistResult.first
//            print("artist name:", artist?.name)

            DispatchQueue.main.async {
                print("artistResult:",artistResult)
                let artist = artistResult.first
                print("artist name:", artist?.name)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showPlaylistGenerated" && shouldPerformSegue(withIdentifier: "showPlaylistGenerated", sender: self) {
            let destination = segue.destination as! NewPlaylistViewController
            print(artistInput.text)
            destination.playlistName = playlistNameInput.text
        }
    }
    
    override func shouldPerformSegue(withIdentifier: String, sender: Any?) -> Bool {
        if withIdentifier == "showPlaylistGenerated" {
            guard let artistInput = artistInput.text, !artistInput.isEmpty else {
                displayMessage(title: "Error", message: "Please enter an artist")
                return false
            }
            guard let playlistNameInput = playlistNameInput.text, !playlistNameInput.isEmpty else {
                displayMessage(title: "Error", message: "Please enter a playlist name")
                return false
            }
        }
        return true
    }
    
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
