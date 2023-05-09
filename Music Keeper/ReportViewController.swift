//
//  ReportViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 04/05/2023.
//

import UIKit
import AVFoundation

class ReportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AVAudioPlayerDelegate {

    @IBOutlet weak var timeRangeSegmentedControl: UISegmentedControl!
    
    // properties for taste analysis
    @IBOutlet weak var energyLabel: UILabel!
    @IBOutlet weak var happinessLabel: UILabel!
    @IBOutlet weak var obscurityLabel: UILabel!
    @IBOutlet weak var genreDecadeLabel: UILabel!
    
    // properties for top artist and top track view
    @IBOutlet weak var topItemsView: UIView!
    @IBOutlet weak var topArtistImageView: UIImageView!
    @IBOutlet weak var topArtistLabel: UILabel!
    @IBOutlet weak var topTrackImageView: UIImageView!
    @IBOutlet weak var topTrackLabel: UILabel!
    
    // properties to store data fetched from API
    private var topTracks: [Track] = []
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    weak var databaseController: DatabaseProtocol?
    var token: String?
    var timeRangeSelected: Int = 0  // default is 'last month'
    var audioPlayer: AVAudioPlayer?
    var selectedAudioURL: URL?
    var previousSelectedIndexPath: IndexPath?
    var selectedRow = Set<Int>()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("report token:", token!)
        print("report refresh token:", refreshToken)
        
        // setup view
        topItemsView.layer.cornerRadius = 10
        timeRangeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        timeRangeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        
        // fetch data from API
        fetchArtist()
        fetchTracks()
        fetchEnergyAndValence()
        fetchGenreAndDecade()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func timeRangeValueChanged(_ sender: Any) {
        timeRangeSelected = timeRangeSegmentedControl.selectedSegmentIndex
        viewDidLoad()
    }
    
    private func getTimeRange() -> String {
        var timeRange = ""
        switch timeRangeSelected {
        case 0:
            timeRange = "short_term"
        case 1:
            timeRange = "medium_term"
        case 2:
            timeRange = "long_term"
        default:
            timeRange = "short_term"
        }
        return timeRange
    }
    
    private func fetchAudioFeatures(for tracks: [Track], completion: @escaping (Double, Double) -> Void) {
        guard let token = token else { return }
        
        let trackIDs = tracks.map { $0.id }.joined(separator: ",")
        
        NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
            guard let audioFeaturesResult = audioFeaturesResult else { return }
            let audioFeaturesItems = audioFeaturesResult
            
            DispatchQueue.main.async {
                var totalEnergy: Double = 0
                var totalValence: Double = 0
                
                for audioFeatures in audioFeaturesItems {
                    totalEnergy += audioFeatures.energy
                    totalValence += audioFeatures.valence
                }
                
                let averageEnergy = totalEnergy / Double(audioFeaturesItems.count)
                let averageValence = totalValence / Double(audioFeaturesItems.count)
                
                completion(averageEnergy, averageValence)
            }
        }
    }

    private func fetchEnergyAndValence() {
        guard let token = token else { return }
        
        let timeRange = getTimeRange()
        let limit = "50"
        
        NetworkManager.shared.getTopTracks(with: token, timeRange: timeRange, limit: limit) { tracksResult in
            guard let tracksResult = tracksResult else { return }
            let tracks = tracksResult
            
            DispatchQueue.main.async {
                self.fetchAudioFeatures(for: tracks) { averageEnergy, averageValence in
                    print("Average energy: \(averageEnergy)")
                    print("Average valence: \(averageValence)")
                    
                    self.energyLabel.text = "\(Int(averageEnergy * 100))% energy"
                    self.happinessLabel.text = "\(Int(averageValence * 100))% happiness"
                }
            }
        }
    }
    
    private func fetchGenreAndDecade() {
        guard let token = token else { return }

        let timeRange = getTimeRange()
        let limit = "50"

        NetworkManager.shared.getTopArtists(with: token, timeRange: timeRange, limit: limit) { artistResult in
            guard let artistResult = artistResult else { return }
            let artists = artistResult

            DispatchQueue.main.async {
                let (topGenre, obscurity) = self.calculateTopGenreAndObscurity(from: artists)

                NetworkManager.shared.getTopTracks(with: token, timeRange: timeRange, limit: limit) { tracksResult in
                    guard let tracksResult = tracksResult else { return }
                    let tracks = tracksResult

                    DispatchQueue.main.async {
                        let topDecade = self.calculateTopDecade(from: tracks)

                        self.obscurityLabel.text = "\(obscurity)% obscurity score"
                        self.genreDecadeLabel.text = "Your top genre is \(topGenre), top decade is \(topDecade)s."
                    }
                }
            }
        }
    }
    
    private func fetchArtist() {
        guard let token = token else { return }
        
        let timeRange = getTimeRange()
        let limit = "1"
        
        NetworkManager.shared.getTopArtists(with: token, timeRange: timeRange, limit: limit) { artistResult in
            guard let artistResult = artistResult else { return }
            let topArtist = artistResult

            let artist = topArtist[0]
            let artistImageURL = artist.images[1].url

            // set UILabel and UIImageView with the result obtained
            DispatchQueue.main.async {
                // Download image url
                NetworkManager.shared.downloadImage(from: artistImageURL) { image in
                    guard let image = image else { return }
                    DispatchQueue.main.async {
                        self.topArtistLabel.text = artist.name
                        self.topArtistImageView.image = image
                    }
                }
            }
        }
    }
    
    private func fetchTracks() {
        guard let token = token else { return }
        
        let timeRange = getTimeRange()
        let limit = "50"
        
        NetworkManager.shared.getTopTracks(with: token, timeRange: timeRange, limit: limit) { tracksResult in
            guard let tracksResult = tracksResult else { return }
            self.topTracks = tracksResult

            let top1stTrack = tracksResult[0]
            let trackImageURL = top1stTrack.album.images[1].url
            
            DispatchQueue.main.async {
                print("fetch tracks selected row before:", self.selectedRow)
                self.selectedRow.removeAll()
                print("fetch tracks selected row after:", self.selectedRow)
                self.tableView.reloadData()

                NetworkManager.shared.downloadImage(from: trackImageURL) { image in
                    guard let image = image else { return }
                    DispatchQueue.main.async {
                        self.topTrackLabel.text = top1stTrack.name
                        self.topTrackImageView.image = image
                    }
                }
            }
        }
    }
    
    private func calculateTopGenreAndObscurity(from artists: [Artist]) -> (String, Int) {
        var genreCounts: [String: Int] = [:]
        var artistPopularity = 0

        for artist in artists {
            for genre in artist.genres {
                genreCounts[genre] = (genreCounts[genre] ?? 0) + 1
            }
            artistPopularity += artist.popularity
        }

        let sortedGenres = genreCounts.sorted { $0.value > $1.value }
        let topGenre = sortedGenres[0].key
        let obscurity = 100 - (artistPopularity / artists.count)

        return (topGenre, obscurity)
    }

    private func calculateTopDecade(from tracks: [Track]) -> Int {
        var decadeFrequency: [Int: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for track in tracks {
            let date = dateFormatter.date(from: track.album.release_date)
            guard let date = date, let year = Calendar.current.dateComponents([.year], from: date).year else { continue }
            let decade = year - (year % 10)
            decadeFrequency[decade, default: 0] += 1
        }
        
        // Find the decade with the highest frequency
        let topDecade = decadeFrequency.max { $0.value < $1.value }!.key
        
        return topDecade
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
            self?.selectedAudioURL = url
            self?.audioPlayer?.delegate = self
            audioPlayer.play()
        }.resume()
    }
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topTrackCell", for: indexPath) as! TopTrackCell
        let topTrack = topTracks[indexPath.row]
        cell.trackLabel.text = topTrack.name
        cell.artistLabel.text = topTrack.artists[0].name
        cell.numberLabel.text = "#" + "\(indexPath.row + 1)"
        cell.audioURL = URL(string: topTrack.preview_url)
        
        if selectedRow.contains(indexPath.row) {
            cell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
        } else {
            cell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Get the selected cell and its associated MP3 URL
        let selectedCell = tableView.cellForRow(at: indexPath) as! TopTrackCell
//        selectedRow.insert(indexPath.row)
        print("didselect start selected row:", selectedRow)
        guard let mp3URL = selectedCell.audioURL else { return }

        // Check if the selected cell is the same as the previously selected cell
        if mp3URL == selectedAudioURL {
            if let audioPlayer = audioPlayer {
                if audioPlayer.isPlaying {
                    // If it is currently playing, pause the audio player
                    audioPlayer.pause()
                    print("indexpath to remove:",indexPath.row)
//                    selectedRow.remove(indexPath.row)
                    selectedCell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal) // Set the play button image
                } else {
                    // If it is currently paused, resume playing the audio
                    audioPlayer.play()
                    print("indexpath to insert:",indexPath.row)
//                    selectedRow.insert(indexPath.row)
                    selectedCell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal) // Set the pause button image
                }
            }
        } else {
            // Stop the previous audio if it's playing
            if let audioPlayer = audioPlayer, audioPlayer.isPlaying {
                audioPlayer.stop()
                // Reset the play button image of the previously selected cell to default (play button)
                print("prev index path playing:",previousSelectedIndexPath?.row)
                let previousIndexPath = previousSelectedIndexPath
                let previousCell = tableView.cellForRow(at: previousIndexPath!) as? TopTrackCell
                print("previousCell:", previousCell)
                if let previousIndexPath = previousSelectedIndexPath, let previousCell = tableView.cellForRow(at: previousIndexPath) as? TopTrackCell {
                    print("indexpath to remove:",previousIndexPath.row)
//                    selectedRow.remove(previousIndexPath.row)
                    previousCell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
                }
            }
            // Play the selected audio
            downloadAndPlayAudio(from: mp3URL)
            print("indexpath to insert:",indexPath.row)
//            selectedRow.insert(indexPath.row)
            selectedCell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal) // Set the pause button image
        }

        // Store the currently selected index path as the previous selected index path
        previousSelectedIndexPath = indexPath
        
        tableView.deselectRow(at: indexPath, animated: true)
        print("didselect end selected row:", selectedRow)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let topTrackCell = cell as? TopTrackCell {
            // Check if the cell's index path matches the previously selected index path
            if indexPath == previousSelectedIndexPath {
                topTrackCell.playButton.setImage(UIImage(systemName: "pause.circle"), for: .normal)
            } else {
                topTrackCell.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
//        if let cell = tableView.cellForRow(at: indexPath) {
//            selectedRow.remove(indexPath.row)
//        }
//    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let selectedIndexPath = previousSelectedIndexPath {
            let selectedCell = tableView.cellForRow(at: selectedIndexPath) as? TopTrackCell
            selectedCell?.playButton.setImage(UIImage(systemName: "play.circle"), for: .normal)
        }
    }
}

class TopTrackCell: UITableViewCell {
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    
    var audioURL: URL?
}
