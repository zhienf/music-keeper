//
//  PlaylistAnalysisCollectionViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 15/05/2023.
//

import UIKit

private let reuseIdentifier = "playlistToAnalyse"

struct PlaylistInfo {
    var playlistTitle: String
    var playlistImage: UIImage
    var playlistID: String
}

class PlaylistAnalysisCollectionViewController: UICollectionViewController {
    
    var indicator = UIActivityIndicatorView()   // displays a spinning animation to indicate loading
    weak var databaseController: DatabaseProtocol?
    var token: String?
    var allPlaylists: [Playlist] = []
    var allPlaylistInfo: [PlaylistInfo] = []
    var totalNumberOfPlaylists: Int = 0
    private let itemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(
      top: 50.0,
      left: 20.0,
      bottom: 50.0,
      right: 20.0)


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(PlaylistToAnalyseCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("analyser token:", token!)
        print("analyser refresh token:", refreshToken)
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = UIColor.lightGray
        self.view.addSubview(indicator)
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        indicator.startAnimating()
        
        fetchPlaylists()
    }
    
    private func fetchPlaylists() {
        guard let token = token else { return }
        let limit = 50 // Number of playlists to fetch per request
        var offset = 0 // Initial offset
        
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
                        print("All playlists fetched")
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return allPlaylists.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PlaylistToAnalyseCell
    
        let playlist = allPlaylistInfo[indexPath.row]
        // Configure the cell using the playlist data
        cell.playlistTitle.text = playlist.playlistTitle
        cell.playlistImage.image = playlist.playlistImage
        // Configure other cell properties
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

// MARK: - Collection View Flow Layout Delegate
extension PlaylistAnalysisCollectionViewController: UICollectionViewDelegateFlowLayout {
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
    
    @IBOutlet weak var playlistImage: UIImageView!
    @IBOutlet weak var playlistTitle: UILabel!
}
