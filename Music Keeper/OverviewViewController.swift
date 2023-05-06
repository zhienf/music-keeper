//
//  OverviewViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

struct ArtistTop5 {
    var artistName: String
    var rank: Int
    var artistImage: UIImage
}

class OverviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
        }
    }
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    // properties for Currently Playing Track view
    @IBOutlet weak var currentlyPlayingTrackTitle: UILabel!
    @IBOutlet weak var currentlyPlayingTrackArtist: UILabel!
    @IBOutlet weak var currentlyPlayingTrackAlbum: UILabel!
    @IBOutlet weak var currentlyPlayingTrackImage: UIImageView!
    @IBOutlet weak var currentlyPlayingView: UIView!
    
    // properties to store data fetched from API
    private var topArtists: [Artist] = []
    private var recentlyPlayedTracks: [PlayHistory] = []
    private var artistTop5Data: [ArtistTop5] = []

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
        print("overview refresh token:", refreshToken ?? "error")
        
        currentlyPlayingView.layer.cornerRadius = 10
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchArtists()
        fetchCurrentlyPlayingTrack()
        fetchRecentlyPlayedTracks()
    }
    
    private func fetchCurrentlyPlayingTrack() {
        guard let token = token else { return }
        NetworkManager.shared.getCurrentlyPlayingTrack(with: token) { trackResult in
            guard let trackResult = trackResult else { return }
            
            let currentSongTitle = trackResult.name
            let currentAlbum = trackResult.album.name
            let currentArtist = trackResult.artists[0].name
            let currentImageURL = trackResult.album.images[1].url

            // set UILabels and UIImageView with the result obtained
            DispatchQueue.main.async {
                self.currentlyPlayingTrackTitle.text = currentSongTitle
                self.currentlyPlayingTrackArtist.text = currentArtist
                self.currentlyPlayingTrackAlbum.text = currentAlbum
                
                // Download image url
                guard let url = URL(string: currentImageURL) else { return }
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
    
    private func fetchArtists() {
        guard let token = token else { return }
        artistTop5Data = []
        NetworkManager.shared.getTopArtists(with: token, timeRange: "short_term", limit: "5") { artistResult in
            guard let artistResult = artistResult else { return }
            let topArtists = artistResult

            let dispatchGroup = DispatchGroup()

            for index in 0..<topArtists.count {
                let artist = topArtists[index]
                let artistImageURL = artist.images[1].url

                // Download image url
                guard let url = URL(string: artistImageURL) else { return }

                dispatchGroup.enter()
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else {
                        print("Failed to download album image: \(error?.localizedDescription ?? "Unknown error")")
                        dispatchGroup.leave()
                        return
                    }
                    DispatchQueue.main.async {
                        let top5Artist = ArtistTop5(artistName: artist.name, rank: index+1, artistImage: UIImage(data: data)!)
                        self.artistTop5Data.append(top5Artist)
                        dispatchGroup.leave()
                    }
                }.resume()
            }

            dispatchGroup.notify(queue: .main) {
                print("image downloaded")
                print(self.artistTop5Data)
                self.collectionView.reloadData()
            }
        }
    }

    
    private func fetchRecentlyPlayedTracks() {
        guard let token = token else { return }
        NetworkManager.shared.getRecentlyPlayedTracks(with: token) { playHistoryResult in
            guard let playHistoryResult = playHistoryResult else { return }
            self.recentlyPlayedTracks = playHistoryResult
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return artistTop5Data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topArtistCell", for: indexPath) as! TopArtistCell
        let top5Artist = artistTop5Data[indexPath.row]
        cell.artistTitle.text = "#" + String(top5Artist.rank) + " " + top5Artist.artistName
        cell.imageView.image = top5Artist.artistImage
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: collectionView.bounds.height)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentlyPlayedTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentlyPlayedCell", for: indexPath)
        let recentlyPlayedTrack = recentlyPlayedTracks[indexPath.row]
        cell.textLabel?.text = recentlyPlayedTrack.track.name
        cell.detailTextLabel?.text = recentlyPlayedTrack.track.artists[0].name
        return cell
    }
}

class TopArtistCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var artistTitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // set attributes and constraints to image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        // add overlay to make image view appear darker
        let overlayView = UIView()
        overlayView.backgroundColor = .black
        overlayView.alpha = 0.2
        imageView.addSubview(overlayView)

        // Add constraints to make the overlay view cover the image view
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
    }
}
