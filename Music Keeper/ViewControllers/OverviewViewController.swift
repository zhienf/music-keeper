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
//            collectionView.register(TopArtistCell.self, forCellWithReuseIdentifier: "topArtistCell")
        }
    }
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
    
    private var topArtists: [Artist] = []
    private var currentlyPlayingTrack: Track?
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
        print("overview refresh token:", refreshToken)
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
    
//    private func fetchArtists() {
//        guard let token = token else { return }
//        NetworkManager.shared.getArtists(with: token) { artistResult in
//            guard let artistResult = artistResult else { return }
//            self.topArtists = artistResult.items
//            DispatchQueue.main.async {
//
//                for index in 0..<self.topArtists.count {
//                    let artist = self.topArtists[index]
//                    let artistImageURL = artist.images?[2].url
//                    // Download image url
//                    guard let imageURL = artistImageURL, let url = URL(string: imageURL) else { return }
//                    URLSession.shared.dataTask(with: url) { (data, response, error) in
//                        guard let data = data, error == nil else {
//                            print("Failed to download album image: \(error?.localizedDescription ?? "Unknown error")")
//                            return
//                        }
//                        DispatchQueue.main.async {
//                            let top5Artist = ArtistTop5(artistName: artist.name, rank: index+1, artistImage: UIImage(data: data)!)
//                            self.artistTop5Data.append(top5Artist)
//                            self.collectionView.reloadData()
//                        }
//                    }.resume()
//                }
//            }
//        }
//    }
    
    private func fetchArtists() {
        guard let token = token else { return }
        NetworkManager.shared.getArtists(with: token) { artistResult in
            guard let artistResult = artistResult else { return }
            self.topArtists = artistResult.items

            let dispatchGroup = DispatchGroup()

            for index in 0..<self.topArtists.count {
                let artist = self.topArtists[index]
                let artistImageURL = artist.images?[2].url

                // Download image url
                guard let imageURL = artistImageURL, let url = URL(string: imageURL) else { return }

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
        NetworkManager.shared.getRecentlyPlayedTracks(with: token) { playHistoryResults in
            guard let playHistoryResults = playHistoryResults else { return }
            self.recentlyPlayedTracks = playHistoryResults.items
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
//        print("imageView: \(cell.imageView)")
//        print("artistTitle: \(cell.artistTitle)")
        cell.artistTitle.text = "#" + String(top5Artist.rank) + " " + top5Artist.artistName
        cell.imageView.image = top5Artist.artistImage
//        cell.data = self.artistTop5Data[indexPath.row]
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
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
//        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        let overlayView = UIView()
        overlayView.backgroundColor = .black
        overlayView.alpha = 0.4
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

//class TopArtistCell: UICollectionViewCell {
//
//    var data: ArtistTop5? {
//        didSet {
//            guard let data = data else { return }
//            artistTitle.text = "#" + String(data.rank) + " " + data.artistName
//            imageView.image = data.artistImage
//
//        }
//    }
//    @IBOutlet weak var imageView: UIImageView! {
//        didSet {
//            imageView.translatesAutoresizingMaskIntoConstraints = false
//            imageView.contentMode = .scaleAspectFill
//            imageView.clipsToBounds = true
//            imageView.layer.cornerRadius = 16
//            imageView.layer.masksToBounds = true
//        }
//    }
//    @IBOutlet weak var artistTitle: UILabel!
//
////    let imageView: UIImageView = {
////        let iv = UIImageView()
////        iv.translatesAutoresizingMaskIntoConstraints = false
////        iv.contentMode = .scaleAspectFill
////        iv.clipsToBounds = true
////        iv.layer.cornerRadius = 16
////        iv.layer.masksToBounds = true
////        return iv
////    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
////        setupViews()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
//    func setupViews() {
////        contentView.addSubview(imageView)
//
//        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
//        imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
//        imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
//        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
//    }
//
//}