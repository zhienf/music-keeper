//
//  OverviewViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

enum ImageError: Error {
    case invalidServerResponse
    case invalidShowURL
    case invalidBookImageURL
}

class OverviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    @IBOutlet weak var currentlyPlayingTrackTitle: UILabel!
    @IBOutlet weak var currentlyPlayingTrackArtist: UILabel!
    @IBOutlet weak var currentlyPlayingTrackAlbum: UILabel!
    @IBOutlet weak var currentlyPlayingTrackImage: UIImageView!
    
    private var artists: [Artist] = []
    private var currentlyPlayingTrack: Track?

    var token: String?
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("overview token:", token!)
        print("overview refresh token:", refreshToken)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchArtists()
        fetchCurrentlyPlayingTrack()
    }
    
    private func fetchArtists() {
        guard let token = token else { return }
        NetworkManager.shared.getArtists(with: token) { artistResult in
            guard let artistResult = artistResult else { return }
            self.artists = artistResult.items
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func fetchCurrentlyPlayingTrack() {
        guard let token = token else { return }
        NetworkManager.shared.getCurrentlyPlayingTrack(with: token) { trackResult in
            guard let trackResult = trackResult else { return }
            self.currentlyPlayingTrack = trackResult
            
            let currentSongTitle = trackResult.name
            let currentAlbum = trackResult.album.name
            let currentArtist = trackResult.artists[0].name
            let currentImageURL = trackResult.album.images?[2].url

            // set UILabels and UIImageView with the result obtained
            DispatchQueue.main.async {
                self.currentlyPlayingTrackTitle.text = currentSongTitle
                self.currentlyPlayingTrackArtist.text = currentArtist
                self.currentlyPlayingTrackAlbum.text = currentAlbum
                
                // Download image url
                guard let imageURL = currentImageURL, let url = URL(string: imageURL) else { return }
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else {
                        print("Failed to download album image: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    DispatchQueue.main.async {
                        self.currentlyPlayingTrackImage.image = UIImage(data: data)
                    }
                }.resume()
            }
        }
    }

    
// MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "librarySongCell", for: indexPath)
//        cell.contentView.backgroundColor = .black
        var content = cell.defaultContentConfiguration()
        let artist = artists[indexPath.row]
        content.text = artist.name
        content.textProperties.color = .white
        cell.contentConfiguration = content
        return cell
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
