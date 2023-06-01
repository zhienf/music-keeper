//
//  PlaylistAnalysisCollectionViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 15/05/2023.
//
// References:
// 1) FIT3178 Week 5 Lab Exercise - Adding a loading indicator view
// 2) https://developer.apple.com/documentation/uikit/uicollectionviewdelegateflowlayout
// 3) https://youtu.be/F6JNvzuldxg (How to UICollectionView Flow Layout)

import UIKit

/**
 A model representing the playlist information required for collection view display.
 
 Usage:
 1. Data is used for displaying the playlist information in the collection view.
 */
struct PlaylistInfo {
    var playlistTitle: String
    var playlistImage: UIImage
    var playlistID: String
}

/**
 A view controller that displays a list of playlists from user's Spotify library.

 This class is a subclass of UICollectionViewController and conforms to UICollectionViewDelegateFlowLayout protocols.

 Usage:
 1. Displays a collection of playlists from user's Spotify library, allows selection for playlist analysis.
 */
class PlaylistAnalysisCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let reuseIdentifier = "playlistToAnalyse"
    
    // properties to retrieve access token for API calls
    var token: String?
    weak var databaseController: DatabaseProtocol?
    
    // displays a spinning animation to indicate loading
    var indicator = UIActivityIndicatorView()
    
    // properties for collection view flow layout
    private let itemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(
      top: 50.0,
      left: 20.0,
      bottom: 50.0,
      right: 20.0)
    
    // properties to store data fetched from API
    var allPlaylists: [Playlist] = []
    var allPlaylistInfo: [PlaylistInfo] = []
    var totalNumberOfPlaylists: Int = 0

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
        
        fetchPlaylists()
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
    
    private func fetchPlaylists() {
        /**
         Retrieves all playlists from the API using pagination to fetch a specified number of playlists per request. It also downloads playlist images asynchronously and processes the fetched data.
         */
        guard let token = token else { return }
        let limit = 50 // Number of playlists to fetch per request
        let offset = 0 // Initial offset
        
        // Create a dispatch group to track the completion of image downloads
        let downloadGroup = DispatchGroup()
        
        // Create a concurrent queue for appending playlist info objects
        let queue = DispatchQueue(label: "playlistInfoQueue", attributes: .concurrent)
        
        // Define a recursive function to fetch playlists
        func fetchPlaylistsRecursive(offset: Int) {
            // Make the API request to fetch playlists with the specified limit and offset
            NetworkManager.shared.getPlaylists(with: token, limit: limit, offset: offset) { playlistResult in
                guard let playlistFetched = playlistResult.0,
                      let totalNumberOfPlaylists = playlistResult.1 else { return }
                
                // Append the fetched playlists to the allPlaylists array
                self.allPlaylists.append(contentsOf: playlistFetched)
                self.totalNumberOfPlaylists = totalNumberOfPlaylists
                
                // Check if there are more playlists to fetch
                if playlistFetched.count < limit {
                    DispatchQueue.main.async {
                        // Update UI or perform other tasks related to fetched playlists
                        for playlist in self.allPlaylists {
                            let playlistTitle = playlist.name
                            let playlistID = playlist.id
                            if let playlistImageURL = playlist.images.first?.url {
                                downloadGroup.enter() // Enter the dispatch group

                                NetworkManager.shared.downloadImage(from: playlistImageURL) { [weak self] image in
                                    guard let self = self, let image = image else {
                                        downloadGroup.leave() // Leave the dispatch group if the image download fails
                                        return
                                    }

                                    let playlistInfo = PlaylistInfo(playlistTitle: playlistTitle, playlistImage: image, playlistID: playlistID)
                                    queue.async(flags: .barrier) {
                                        self.allPlaylistInfo.append(playlistInfo)
                                    }
                                    downloadGroup.leave() // Leave the dispatch group after successful image download
                                }
                            }
                        }
                        
                        // Notify when all image downloads have completed
                        downloadGroup.notify(queue: .main) {
                            self.indicator.stopAnimating()
                            self.collectionView.reloadData()
                        }
                    }
                } else {
                    // Fetch the next batch of playlists recursively
                    let newOffset = offset + limit
                    fetchPlaylistsRecursive(offset: newOffset)
                }
            }
        }
        // Start fetching playlists recursively with initial offset
        fetchPlaylistsRecursive(offset: offset)
    }

     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using [segue destinationViewController].
         // Pass the selected object to the new view controller.
        if segue.identifier == "showPlaylistSummary" {
            if let cell = sender as? UICollectionViewCell, let indexPath = collectionView.indexPath(for: cell) {
                let controller = segue.destination as! PlaylistSummaryViewController
                controller.currentPlaylist = allPlaylistInfo[indexPath.row]
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // return the number of items
        return allPlaylists.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlaylistToAnalyseCell
    
        let playlist = allPlaylistInfo[indexPath.row]
        // Configure the cell using the playlist data
        cell.playlistTitle.text = playlist.playlistTitle
        cell.playlistImage.image = playlist.playlistImage
    
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
      let availableWidth = view.frame.width - paddingSpace
      let widthPerItem = availableWidth / itemsPerRow
      
      return CGSize(width: widthPerItem, height: widthPerItem * 1.2)
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
      return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      return sectionInsets.left
    }
}

class PlaylistToAnalyseCell: UICollectionViewCell {
    /**
     Custom collection view cell used in PlaylistAnalysisCollectionViewController.
     */
    @IBOutlet weak var playlistImage: UIImageView!
    @IBOutlet weak var playlistTitle: UILabel!
}
