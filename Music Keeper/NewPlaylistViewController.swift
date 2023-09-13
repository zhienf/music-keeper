//
//  NewPlaylistViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 17/05/2023.
//
// References:
// 1) https://developer.spotify.com/documentation/ios/tutorials/content-linking

import UIKit
import AVFoundation

/**
 A view controller that displays the newly generated playlist information based on a given artist name from the previous view controller.

 This class is a subclass of UIViewController and conforms to UITableViewDelegate, and UITableViewDataSource protocols.

 Usage:
 1. Displays the playlist information of the newly generated playlist information based on a given artist name from the previous view controller.
 2. Allows user to view the playlist in Spotify app through deep linking.
 */
class NewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {
    
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
    
    // properties for audio player
    var audioPlayer: AVAudioPlayer?
    var selectedAudioURL: URL?
    var previousSelectedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        
        // Allows sound playback regardless of the silent mode switch position
        configureAudioSession()
        
        // Add a loading indicator view
        setupIndicator()
        
        fetchSearchItem()

        guard let playlistName = playlistName else { return }
        playlistTitle.text = playlistName
    }
    
    func configureAudioSession() {
        // Allows sound playback regardless of the silent mode switch position
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback)
            try audioSession.setActive(true)
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
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
    
    private func downloadAndPlayAudio(from url: URL) {
        /**
         Handle the asynchronous downloading of the audio file. It creates a URLSession data task to download the audio data, and upon completion, it attempts to create an AVAudioPlayer instance using the downloaded data.
         */
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, let audioPlayer = try? AVAudioPlayer(data: data) else {
                if let error = error {
                    print("Failed to load audio: \(error)")
                }
                return
            }

            self?.audioPlayer = audioPlayer
            self?.selectedAudioURL = url    // current mp3 url to play
            self?.audioPlayer?.delegate = self  // to keep track of the state of audio player
            audioPlayer.play()
        }.resume()
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistTrackCell", for: indexPath) as! NewPlaylistTrackCell
        let playlistTrack = playlistTracks[indexPath.row]
        cell.trackLabel.text = playlistTrack.name
        cell.artistLabel.text = playlistTrack.artists[0].name
        cell.audioURL = URL(string: playlistTrack.preview_url)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the selected cell and its associated MP3 URL
        let selectedCell = tableView.cellForRow(at: indexPath) as! NewPlaylistTrackCell
        guard let mp3URL = selectedCell.audioURL else { return }

        // Check if the selected cell is the same as the previously selected cell
        if mp3URL == selectedAudioURL {
            if let audioPlayer = audioPlayer {
                if audioPlayer.isPlaying {
                    // If it is currently playing, pause the audio player
                    audioPlayer.pause()
                    selectedCell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
                } else {
                    // If it is currently paused, resume playing the audio
                    audioPlayer.play()
                    selectedCell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
                }
            }
        } else {
            // Stop the previous audio if it's playing
            if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
                audioPlayer.stop()
                // Reset the play button image of the previously selected cell to default (play button)
                // NOTE: won't enter block when table is scrolled, since previous cell has been reused.
                if let previousIndexPath = previousSelectedIndexPath, let previousCell = tableView.cellForRow(at: previousIndexPath) as? NewPlaylistTrackCell {
                    previousCell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
                }
            }
            // Play the selected audio
            downloadAndPlayAudio(from: mp3URL)
            selectedCell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        }

        // Store the currently selected index path as the previous selected index path
        previousSelectedIndexPath = indexPath
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let topTrackCell = cell as? NewPlaylistTrackCell {
            // Update the reused cell when the view scrolls back to it
            // Check if the cell's index path matches the previously selected index path
            if indexPath == previousSelectedIndexPath {
                topTrackCell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            } else {
                topTrackCell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let selectedIndexPath = previousSelectedIndexPath {
            let selectedCell = tableView.cellForRow(at: selectedIndexPath) as? NewPlaylistTrackCell
            selectedCell?.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
    }
}

class NewPlaylistTrackCell: UITableViewCell {
    /**
     Custom table view cell used in NewPlaylistViewController.
     */
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    
    var audioURL: URL?
}

