//
//  PlaylistSummaryViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 16/05/2023.
//
// References:
// 1) https://developer.spotify.com/documentation/ios/tutorials/content-linking

import UIKit

/**
 A view controller that displays the summary of a playlist selected.

 This class is a subclass of UIViewController.

 Usage:
 1. Displays a summary of the playlist selected (playlist mood, top genre, most repeated artist, most repeated pitch)
 2. Allows user to view the playlist in Spotify app through deep linking.
 */
class PlaylistSummaryViewController: UIViewController {

    @IBOutlet weak var playlistImage: UIImageView!
    @IBOutlet weak var playlistTitle: UILabel!
    @IBOutlet weak var playlistDetails: UILabel!
    @IBOutlet weak var playlistMood: UILabel!
    @IBOutlet weak var playlistGenre: UILabel!
    @IBOutlet weak var playlistRepeatedArtist: UILabel!
    @IBOutlet weak var playlistRepeatedDecade: UILabel!
    @IBOutlet weak var playlistMainGenres: UILabel!
    
    // properties to retrieve access token for API calls
    var token: String?
    weak var databaseController: DatabaseProtocol?
    
    // current playlist to analyse
    var currentPlaylist: PlaylistInfo?
    
    // pitch class notation to determine most repeated key
    let pitchClassNotation: [Int: String] = [
        0: "C",
        1: "C#/Db",
        2: "D",
        3: "D#/Eb",
        4: "E",
        5: "F",
        6: "F#/Gb",
        7: "G",
        8: "G#/Ab",
        9: "A",
        10: "A#/Bb",
        11: "B"
    ]
    
    @IBAction func openSpotifyPlaylist(_ sender: Any) {
        guard let playlistID = currentPlaylist?.playlistID else { print("invalid playlist ID"); return }
        
        guard let spotifyDeepLinkURL = URL(string: "spotify:playlist:\(playlistID)") else { print("invalid playlist URI"); return }
    
        guard let spotifyExternalURL = URL(string: "https://open.spotify.com/playlist/\(playlistID)") else { print("invalid playlist external URL"); return }
        
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController

        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        
        // Setup views
        playlistImage.image = currentPlaylist?.playlistImage
        playlistTitle.text = currentPlaylist?.playlistTitle

        fetchPlaylistTracks()
    }
    
    private func fetchPlaylistTracks() {
        /**
         Get tracks of the playlist for analysis.
         */
        guard let token = token, let playlistID = currentPlaylist?.playlistID else { return }
        
        NetworkManager.shared.getPlaylistTracks(with: token, playlistID: playlistID) { trackResult in
            guard let trackResult = trackResult else { return }
            let playlistTracks = trackResult
        
            DispatchQueue.main.async {
                self.fetchAudioFeatures(for: playlistTracks) { averageEnergy, averageValence, averageDanceability, topKey in
                    if averageEnergy >= 0.5 {
                        self.playlistMood.text = "Energetic"
                    } else {
                        self.playlistMood.text = "Chill"
                    }
                    self.playlistRepeatedDecade.text = topKey
                }
                self.calculateTopGenreAndArtist(from: playlistTracks) { topGenres, topArtist, artistNum in
                    // Handle the top genre here
                    self.playlistGenre.text = topGenres.first
                    self.playlistMainGenres.text = topGenres.joined(separator: "\n")
                    self.playlistRepeatedArtist.text = topArtist
                    self.playlistDetails.text = "\(playlistTracks.count) tracks by \(artistNum) artists"
                }
            }
        }
    }
    
    private func calculateTopGenreAndArtist(from tracks: [Track], completion: @escaping (([String], String, Int)) -> Void) {
        /**
         Calculates top genre and top artist based on the tracks from the playlist selected.
         */
        guard let token = token else {
            completion(([], "", 0))
            return
        }
        
        var artists: [Artist] = []

        for track in tracks {
            for artist in track.artists {
                artists.append(artist)
            }
        }

        let artistIDsArray = artists.map { $0.id }
        let batchSize = 50 // Maximum number of artist IDs per request
        var currentIndex = 0

        // dispatchGroup to keep track of the asynchronous API requests
        let dispatchGroup = DispatchGroup()
        var combinedResults: [Artist] = []

        while currentIndex < artistIDsArray.count {
            let endIndex = min(currentIndex + batchSize, artistIDsArray.count)
            let batchArtistIDs = Array(artistIDsArray[currentIndex..<endIndex])
            let batchArtistIDsString = batchArtistIDs.joined(separator: ",")
            
            // Each time we enter the loop, we enter the dispatchGroup
            dispatchGroup.enter()
            
            NetworkManager.shared.getArtists(with: token, ids: batchArtistIDsString) { artistsResult in
                defer {
                    // inside the completion handler of each API request, we leave the dispatchGroup
                    dispatchGroup.leave()
                }
                
                guard let artistsResult = artistsResult else { return }
                
                combinedResults.append(contentsOf: artistsResult)
            }
            currentIndex += batchSize
        }

        dispatchGroup.notify(queue: .main) {
            var genreCounts: [String: Int] = [:]
            var artistCounts: [String: Int] = [:]

            for artist in combinedResults {
                for genre in artist.genres {
                    genreCounts[genre] = (genreCounts[genre] ?? 0) + 1
                }
                artistCounts[artist.name] = (artistCounts[artist.name] ?? 0) + 1
            }

            let sortedGenres = genreCounts.sorted { $0.value > $1.value }
            let topGenres = sortedGenres.prefix(5).map { $0.key }
            
            let sortedArtists = artistCounts.sorted { $0.value > $1.value }
            let topArtist = sortedArtists.first?.key ?? ""

            completion((topGenres, topArtist, artistCounts.count))
        }
    }
    
    private func fetchAudioFeatures(for tracks: [Track], completion: @escaping (Double, Double, Double, String) -> Void) {
        /**
         Get audio features of the tracks from the playlist for analysis, by calculating the averages of energy, valence, danceability and key counts of the tracks.
         */
        guard let token = token else { return }
        
        let trackIDs = tracks.map { $0.id }.joined(separator: ",")
        
        NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
            guard let audioFeaturesResult = audioFeaturesResult else { return }
            let audioFeaturesItems = audioFeaturesResult
            
            DispatchQueue.main.async {
                var totalEnergy: Double = 0
                var totalValence: Double = 0
                var totalDanceability: Double = 0
                var keyCounts: [Int: Int] = [:]
                
                for audioFeatures in audioFeaturesItems {
                    totalEnergy += audioFeatures.energy
                    totalValence += audioFeatures.valence
                    totalDanceability += audioFeatures.danceability
                    keyCounts[audioFeatures.key] = (keyCounts[audioFeatures.key] ?? 0) + 1
                }
                
                let averageEnergy = totalEnergy / Double(audioFeaturesItems.count)
                let averageValence = totalValence / Double(audioFeaturesItems.count)
                let averageDanceability = totalDanceability / Double(audioFeaturesItems.count)
                let sortedKeys = keyCounts.sorted { $0.value > $1.value }
                let topKey = self.pitchClassNotation[sortedKeys[0].key] ?? ""

                completion(averageEnergy, averageValence, averageDanceability, topKey)
            }
        }
    }
}
