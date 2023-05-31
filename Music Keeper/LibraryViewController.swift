//
//  LibraryViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit
import AVFoundation

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate, MoodChangeDelegate {
    
    @IBOutlet weak var songsCount: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    @IBAction func filterSongs(_ sender: Any) {
        // stop audio player if it's still playing
        if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
            audioPlayer.stop()
        }
        
        // clear previously selected index path to reset play buttons of table view
        previousSelectedIndexPath = nil
        viewDidLoad()
    }
    
    @IBAction func savePlaylistButton(_ sender: Any) {
        let overLayer = OverLayerPopUp()
        overLayer.songsCount = songList.count
        overLayer.songListToSave = songList
        overLayer.appear(sender: self)
    }
    
    // properties to retrieve access token for API calls
    var token: String?
    weak var databaseController: DatabaseProtocol?
    
    // displays a spinning animation to indicate loading
    var indicator = UIActivityIndicatorView()
    
    // properties for audio player
    var audioPlayer: AVAudioPlayer?
    var selectedAudioURL: URL?
    var previousSelectedIndexPath: IndexPath?
    
    // properties to store data fetched from API
    private var songList: [Track] = []
    
    // properties for filtering library
    var danceabilityValue: Double?
    var energyValue: Double?
    var valenceValue: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        
        // Add a loading indicator view
        setupIndicator()
        
        fetchLibrary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // reset songList to show empty table view
        songList = []
        self.tableView.reloadData()
        viewDidLoad()
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
    
    private func fetchLibrary() {
        guard let token = token else { return }
        var allTracks: [Track] = [] // Array to store all fetched tracks
        let limit = 50
        let offset = 0
        
        // Function to recursively fetch tracks using pagination
        func fetchTracks(offset: Int) {
            NetworkManager.shared.getSavedTracks(with: token, limit: limit, offset: offset) { tracksResult in
                guard let tracksResult = tracksResult else { return }
                allTracks.append(contentsOf: tracksResult)

                // Check if there are more tracks to fetch
                if tracksResult.count < limit {
                    self.filterSongsByAudioFeatures(allTracks) { filteredSongs in
                        DispatchQueue.main.async {
                            self.songList = filteredSongs
                            self.songsCount.text = "\(filteredSongs.count) songs"
                            self.indicator.stopAnimating()
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    let newOffset = offset + limit
                    fetchTracks(offset: newOffset)
                }
            }
        }
        // Start fetching tracks with an initial offset of 0
        fetchTracks(offset: offset)
    }
    
    private func filterSongsByAudioFeatures(_ tracks: [Track], completion: @escaping ([Track]) -> Void) {
        guard let token = token else { return }
        
        let trackIDs = tracks.map { $0.id }.joined(separator: ",")
        
        NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
            guard let audioFeaturesResult = audioFeaturesResult else { return }
            let audioFeaturesItems = audioFeaturesResult
            
            DispatchQueue.main.async {
                // Filtering songs based on danceability, energy, and valence
                if let danceabilityValue = self.danceabilityValue,
                   let energyValue = self.energyValue,
                   let valenceValue = self.valenceValue {
                    print(danceabilityValue, energyValue, valenceValue)
                    let filteredSongs = tracks.filter { savedTrack in
                        guard let audioFeature = audioFeaturesItems.first(where: { $0.id == savedTrack.id }) else {
                            return false
                        }
                        
                        let (danceabilityLowerBound, danceabilityUpperBound) = self.calculateBounds(value: danceabilityValue)
                        let (energyLowerBound, energyUpperBound) = self.calculateBounds(value: energyValue)
                        let (valenceLowerBound, valenceUpperBound) = self.calculateBounds(value: valenceValue)
                        
                        return (danceabilityLowerBound...danceabilityUpperBound).contains(audioFeature.danceability) &&
                            (energyLowerBound...energyUpperBound).contains(audioFeature.energy) &&
                            (valenceLowerBound...valenceUpperBound).contains(audioFeature.valence)
                    }
                    completion(filteredSongs) // Return the filtered songs through the completion closure
                } else {
                    completion(tracks) // Return the original list of tracks
                }
            }
        }
    }
    
    private func calculateBounds(value: Double) -> (lowerBound: Double, upperBound: Double) {
        var lowerBound = 0.0
        var upperBound = 1.0
        if value != 0.0 {
            lowerBound = value - 0.2
            upperBound = value + 0.2
        }
        return (lowerBound, upperBound)
    }
    
    private func downloadAndPlayAudio(from url: URL) {
        // handle the asynchronous downloading of the audio file. It creates a URLSession data task to download the audio data, and upon completion, it attempts to create an AVAudioPlayer instance using the downloaded data.
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
        return songList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "librarySongCell", for: indexPath) as! LibrarySongCell
        let song = songList[indexPath.row]
        cell.trackLabel.text = song.name
        cell.artistLabel.text = song.artists[0].name
        cell.audioURL = URL(string: song.preview_url)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the selected cell and its associated MP3 URL
        let selectedCell = tableView.cellForRow(at: indexPath) as! LibrarySongCell
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
                if let previousIndexPath = previousSelectedIndexPath, let previousCell = tableView.cellForRow(at: previousIndexPath) as? LibrarySongCell {
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
        if let topTrackCell = cell as? LibrarySongCell {
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
            let selectedCell = tableView.cellForRow(at: selectedIndexPath) as? LibrarySongCell
            selectedCell?.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
    }
    
    // MARK: - MoodChangeDelegate
    
    func changedToValues(_ values: (Double, Double, Double)) {
        danceabilityValue = values.0
        energyValue = values.1
        valenceValue = values.2
    }
    
    func resetValues() {
        danceabilityValue = nil
        energyValue = nil
        valenceValue = nil
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "filterLibrarySegue" {
            let destination = segue.destination as! FilterSongViewController
            destination.songsCount = songList.count
            destination.librarySongs = songList
            destination.initialValues = (danceabilityValue ?? 0, energyValue ?? 0, valenceValue ?? 0)
            destination.delegate = self
        }
    }
}

class LibrarySongCell: UITableViewCell {
    
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var audioURL: URL?
}
