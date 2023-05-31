//
//  GeneratePlaylistViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 17/05/2023.
//

import UIKit

/**
 A view controller that generates a random playlist based on a given artist name.

 This class is a subclass of UIViewController.

 Usage:
 1. Generates a random playlist based on a given artist name.
 2. Artist name input will be used to get track recommendations for the new playlist.
 3. Allows user to name the new playlist to be generated.
 */
class GeneratePlaylistViewController: UIViewController {

    @IBOutlet weak var artistInput: UITextField!
    @IBOutlet weak var playlistNameInput: UITextField!
    @IBOutlet weak var generatePlaylistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showPlaylistGenerated" && shouldPerformSegue(withIdentifier: "showPlaylistGenerated", sender: self) {
            let destination = segue.destination as! NewPlaylistViewController
            destination.searchQuery = artistInput.text
            destination.playlistName = playlistNameInput.text
        }
    }
    
    override func shouldPerformSegue(withIdentifier: String, sender: Any?) -> Bool {
        /**
         Validates the text field input and makes sure they are not left empty.
         */
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
