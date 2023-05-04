//
//  ReportViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 04/05/2023.
//

import UIKit

class ReportViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var timeRangeSegmentedControl: UISegmentedControl!
    
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
        
        topItemsView.layer.cornerRadius = 10
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchArtist()
        fetchTracks()
//        fetchCurrentlyPlayingTrack()
//        fetchRecentlyPlayedTracks()
    }
    
    private func fetchArtist() {
        guard let token = token else { return }
        NetworkManager.shared.getArtists(with: token, timeRange: "short_term", limit: "1") { artistResult in
            guard let artistResult = artistResult else { return }
            let topArtist = artistResult.items

            let artist = topArtist[0]
            let artistImageURL = artist.images?[2].url

            // set UILabel and UIImageView with the result obtained
            DispatchQueue.main.async {
                // Download image url
                guard let imageURL = artistImageURL, let url = URL(string: imageURL) else { return }
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
        NetworkManager.shared.getTopTracks(with: token, timeRange: "short_term", limit: "50") { tracksResult in
            guard let tracksResult = tracksResult else { return }
            self.topTracks = tracksResult.items
            
            let top1stTrack = self.topTracks[0]
            let trackImageURL = top1stTrack.album.images?[2].url
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                guard let imageURL = trackImageURL, let url = URL(string: imageURL) else { return }
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
