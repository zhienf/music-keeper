//
//  OverLayerPopUp.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class OverLayerPopUp: UIViewController {
    
    var songsCount: Int?
    var songListToSave: [Track]?
    var token: String?
    weak var databaseController: DatabaseProtocol?

    @IBOutlet weak var songsCountLabel: UILabel!
    @IBOutlet weak var playlistNameTextField: UITextField!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var popUpView: UIView!
    
    @IBAction func cancelButton(_ sender: Any) {
        hide()
    }
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func saveButton(_ sender: Any) {
        guard let playlistName = playlistNameTextField.text, !playlistName.isEmpty else {
            displayMessage(title: "Error", message: "Please enter a playlist name")
            return
        }
        
        guard let token = token, let songListToSave = songListToSave else { return }
        let trackURIsArray = songListToSave.map { $0.uri }
        
        NetworkManager.shared.createPlaylist(with: token, songs: trackURIsArray, playlistName: playlistName) { playlist in
            guard let playlist = playlist else { return }
            print("playlist created:", playlist.name)
            
            DispatchQueue.main.async {
//                self.hide()
//                self.displayMessage(title: "New Playlist", message: "Playlist saved!")
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
        print("overlayer token:", token!)
        print("overlayer refresh token:", refreshToken)

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
    
//    func displayMessage(title: String, message: String) {
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
//        self.present(alertController, animated: true, completion: nil)
//    }
    
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
