//
//  OverLayerPopUp.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//
// References:
// 1) https://youtu.be/WIT4f23M2DI (Custom PopUp Overlayer View)
// 2) https://youtu.be/LeRReD56TgI (Custom UITextField in Swift)

import UIKit

/**
 A view controller that displays an overlayer for user to create a new playlist for the filtered tracks with a custom playlist name.

 This class is a subclass of UIViewController.

 Usage:
 1. Displays an overlayer for user to create a new playlist for the filtered tracks.
 2. Allows user to provide a custom playlist name to be saved.
 */
class OverLayerPopUp: UIViewController {
    
    @IBOutlet weak var songsCountLabel: UILabel!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var saveButton: UIButton!
    
    // properties storing track information for new playlist
    var songsCount: Int?
    var songListToSave: [Track]?
    
    // properties to retrieve access token for API calls
    var token: String?
    weak var databaseController: DatabaseProtocol?
    
    @IBAction func cancelButton(_ sender: Any) {
        hide()
    }
    
    @IBAction func saveButton(_ sender: Any) {
        // checks the text field and makes sure it is not left empty
        guard let playlistName = playlistNameTextField.text, !playlistName.isEmpty else {
            displayMessage(title: "Error", message: "Please enter a playlist name")
            return
        }
        
        guard let token = token, let songListToSave = songListToSave else { return }
        let trackURIsArray = songListToSave.map { $0.uri }
        
        NetworkManager.shared.createPlaylist(with: token, songs: trackURIsArray, playlistName: playlistName) { playlist in
            guard let playlist = playlist else { return }
            
            DispatchQueue.main.async {
                // displays a pop up message to inform playlist successfully saved before dismissing the overlayer
                self.displayMessage(title: "New Playlist", message: "Playlist saved!") {
                    self.hide()
                }
            }
        }
    }
    
    init() {
        super.init(nibName: "OverLayerPopUp", bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()

        configView()
    }
    
    func configView() {
        self.view.backgroundColor = .clear
        self.backView.backgroundColor = .black.withAlphaComponent(0.6)
        self.backView.alpha = 0
        self.popUpView.alpha = 0
        self.popUpView.layer.cornerRadius = 10
        if let songsCount = songsCount {
            self.songsCountLabel.text = "\(songsCount) songs to save"
        }
    }

    func appear(sender: UIViewController) {
        sender.present(self, animated: false) {
            self.show()
        }
    }
    
    private func show() {
        self.backView.alpha = 1
        self.popUpView.alpha = 1
    }
    
    func hide() {
        self.backView.alpha = 0
        self.popUpView.alpha = 0
        self.dismiss(animated: false)
        self.removeFromParent()
    }
    
    func displayMessage(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in
            completion?() // Call the completion handler if provided
        })
        self.present(alertController, animated: true, completion: nil)
    }
}

class CustomTextField: UITextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Customize the text field appearance
        self.tintColor = .systemGreen  // Set the cursor color
        self.textColor = .black
        
        // Set the placeholder text color
        if let placeholder = self.placeholder {
            self.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        }
        
        // Customize the border color and width
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 0.5
        self.borderStyle = .roundedRect
    }
}
