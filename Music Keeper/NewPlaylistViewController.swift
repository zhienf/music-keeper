//
//  NewPlaylistViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 17/05/2023.
//
// References:
// 1) https://developer.spotify.com/documentation/ios/tutorials/content-linking

import UIKit

/**
 A view controller that displays the newly generated playlist information based on a given artist name from the previous view controller.

 This class is a subclass of UIViewController and conforms to UITableViewDelegate, and UITableViewDataSource protocols.

 Usage:
 1. Displays the playlist information of the newly generated playlist information based on a given artist name from the previous view controller.
 2. Allows user to view the playlist in Spotify app through deep linking.
 */
class NewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playlistImage: UIImageView!
    @IBOutlet weak var playlistTitle: UILabel!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    // properties to retrieve access token for API calls
    var token: String?
    weak var databaseController: DatabaseProtocol?
    
    // displays a spinning animation to indicate loading
    var indicator = UIActivityIndicatorView()
    
    // properties for playlist information to be displayed
    var playlistName: String?
    var searchQuery: String?
    var playlistTracks: [Track] = []
    var playlistURI: String?
    var playlistID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        
        // Add a loading indicator view
        setupIndicator()
        
        fetchSearchItem()

        guard let playlistName = playlistName else { return }
        playlistTitle.text = playlistName
    }
    
    @IBAction func openSpotifyPlaylist(_ sender: Any) {        
        guard let playlistURI = playlistURI, let spotifyDeepLinkURL = URL(string: playlistURI) else { print("invalid playlist URI"); return }
    
        guard let playlistID = playlistID, let spotifyExternalURL = URL(string: "https://open.spotify.com/playlist/\(playlistID)") else { print("invalid playlist external URL"); return }
        
        if UIApplication.shared.canOpenURL(spotifyDeepLinkURL) {
            UIApplication.shared.open(spotifyDeepLinkURL)
        } else {
            // Spotify app is not installed, handle accordingly
            if UIApplication.shared.canOpenURL(spotifyExternalURL) {
                UIApplication.shared.open(spotifyExternalURL, options: [:], completionHandler: nil)
            } else {
                print("cannot open external url")
            }
        }
    }
    
    func setupIndicator() {
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = UIColor.lightGray
        self.view.addSubview(indicator)
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        indicator.startAnimating()
    }
    
    private func fetchSearchItem() {
        /**
         Retrieves search items based on the search query, selects an artist ID, and fetches recommendations based on the artist ID. It then creates a playlist with the specified playlist name using the recommendations. The method also downloads the playlist image and retrieves the tracks of the created playlist.
         */
        guard let token = token, let playlistName = playlistName, let searchQuery = searchQuery else { return }
        // Retrieves search items based on the search query (artist name)
        NetworkManager.shared.searchArtistItems(with: token, query: searchQuery) { artistResult in
            guard let artistResult = artistResult else { return }

            let artistID = artistResult.first?.id

            DispatchQueue.main.async {
                guard let artistID = artistID else { return }
                // Fetches track recommendations based on the artist ID retrieved
                NetworkManager.shared.getRecommendations(with: token, artistID: artistID) { tracksResult in
                    guard let tracksResult = tracksResult else { return }
                    let trackURIsArray = tracksResult.map { $0.uri }
                    print(trackURIsArray)

                    DispatchQueue.main.async {
                        // Creates a playlist with the specific playlist name using the track recommendations.
                        NetworkManager.shared.createPlaylist(with: token, songs: trackURIsArray, playlistName: playlistName) { playlist in
                            guard let playlist = playlist else { return }
                            self.playlistURI = playlist.uri
                            self.playlistID = playlist.id
                            print("playlist created:", playlist.name)

                            DispatchQueue.main.async {
                                guard let playlistImageURL = playlist.images.first?.url else { return }
                                NetworkManager.shared.downloadImage(from: playlistImageURL) { image in
                                    guard let image = image else { return }
                                    DispatchQueue.main.async {
                                        self.playlistImage.image = image
                                        self.indicator.stopAnimating()
                                    }
                                }

                                // Displays the tracks from the playlist
                                NetworkManager.shared.getPlaylistTracks(with: token, playlistID: playlist.id) { tracksResult in
                                    guard let tracksResult = tracksResult else { return }
                                    self.playlistTracks = tracksResult

                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                        self.indicator.stopAnimating()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistTrackCell", for: indexPath)
        let playlistTrack = playlistTracks[indexPath.row]
        cell.textLabel?.text = playlistTrack.name
        cell.detailTextLabel?.text = playlistTrack.artists[0].name
        return cell
    }
}
