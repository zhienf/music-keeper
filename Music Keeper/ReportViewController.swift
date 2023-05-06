//
//  ReportViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 04/05/2023.
//

import UIKit

class ReportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
    
    var token: String?
    
    weak var databaseController: DatabaseProtocol?
    
    var timeRangeSelected: Int = 0  // default is 'last month'
    
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
        fetchEnergy()
        fetchValence()
        fetchGenreDecade()
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
    
    private func fetchEnergy() {
        guard let token = token else { return }
        
        let timeRange = getTimeRange()
        let limit = "50"
        
        NetworkManager.shared.getTopTracks(with: token, timeRange: timeRange, limit: limit) { tracksResult in
            guard let tracksResult = tracksResult else { return }
            let tracks = tracksResult
            
            DispatchQueue.main.async {
                // append track IDs into a list
                var trackIDs = tracks[0].id
                for track in tracks.dropFirst() {
                    trackIDs += ",\(track.id)"
                }
                
                NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
                    guard let audioFeaturesResult = audioFeaturesResult else { return }
                    let audioFeaturesItems = audioFeaturesResult
                    DispatchQueue.main.async {
                        var totalEnergy: Double = 0
                        for audioFeatures in audioFeaturesItems {
                            totalEnergy += audioFeatures.energy
                        }
                        let averageEnergy = totalEnergy / Double(audioFeaturesItems.count)
                        print("Average energy: \(averageEnergy)")
                        
                        if averageEnergy >= 0.5 {
                            self.energyLabel.text = "You listen to a lot of energetic music,"
                        } else {
                            self.energyLabel.text = "You listen to a lot of mellow music,"
                        }
                    }
                }
            }
        }
    }
    
    private func fetchValence() {
        guard let token = token else { return }
        
        let timeRange = getTimeRange()
        let limit = "50"
        
        NetworkManager.shared.getTopTracks(with: token, timeRange: timeRange, limit: limit) { tracksResult in
            guard let tracksResult = tracksResult else { return }
            let tracks = tracksResult
            
            DispatchQueue.main.async {
                // append track IDs into a list
                var trackIDs = tracks[0].id
                for track in tracks.dropFirst() {
                    trackIDs += ",\(track.id)"
                }
                
                NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
                    guard let audioFeaturesResult = audioFeaturesResult else { return }
                    let audioFeaturesItems = audioFeaturesResult
                    DispatchQueue.main.async {
                        var totalValence: Double = 0
                        for audioFeatures in audioFeaturesItems {
                            totalValence += audioFeatures.valence
                        }
                        let averageValence = totalValence / Double(audioFeaturesItems.count)
                        print("Average valence: \(averageValence)")
                        
                        if averageValence >= 0.5 {
                            self.happinessLabel.text = "Your music mood is happy,"
                        } else {
                            self.happinessLabel.text = "Your music mood is sentimental,"
                        }
                    }
                }
            }
        }
    }
    
    private func fetchGenreDecade() {
        guard let token = token else { return }
        
        let timeRange = getTimeRange()
        let limit = "50"
        
        NetworkManager.shared.getTopTracks(with: token, timeRange: timeRange, limit: limit) { tracksResult in
            guard let tracksResult = tracksResult else { return }
            let tracks = tracksResult
            
            DispatchQueue.main.async {
                var genreCounts: [String: Int] = [:]
                for track in tracks {
                    for genre in track.album.genres {
                        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1
                    }
                }
                let sortedGenres = genreCounts.sorted { $0.value > $1.value }
                let topGenres = sortedGenres.prefix(5).map { $0.key }
                print("Top genres: \(topGenres)")
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
                guard let url = URL(string: artistImageURL) else { return }
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else {
                        print("Failed to download album image: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    DispatchQueue.main.async {
                        self.topArtistLabel.text = artist.name
                        self.topArtistImageView.image = UIImage(data: data)
                    }
                }.resume()
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
            
            let top1stTrack = self.topTracks[0]
            let trackImageURL = top1stTrack.album.images[1].url
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                guard let url = URL(string: trackImageURL) else { return }
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else {
                        print("Failed to download album image: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    DispatchQueue.main.async {
                        self.topTrackLabel.text = top1stTrack.name
                        self.topTrackImageView.image = UIImage(data: data)
                    }
                }.resume()
            }
        }
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
        return cell
    }
}

class TopTrackCell: UITableViewCell {
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
}
