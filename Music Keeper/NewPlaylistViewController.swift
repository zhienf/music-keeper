//
//  NewPlaylistViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 17/05/2023.
//

import UIKit

class NewPlaylistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var playlistImage: UIImageView!
    
    @IBOutlet weak var playlistTitle: UILabel!
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    var playlistName: String?
    var searchQuery: String?
    var playlistTracks: [Track] = []
    var indicator = UIActivityIndicatorView()   // displays a spinning animation to indicate loading
    
    weak var databaseController: DatabaseProtocol?
    var token: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("new playlist token:", token!)
        print("new playlist refresh token:", refreshToken)
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = UIColor.lightGray
        self.view.addSubview(indicator)
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        indicator.startAnimating()
        
        fetchSearchItem()

        guard let playlistName = playlistName else { return }
        playlistTitle.text = playlistName
    }
    
    private func fetchSearchItem() {
        guard let token = token, let playlistName = playlistName, let searchQuery = searchQuery else { return }
        NetworkManager.shared.searchArtistItems(with: token, query: searchQuery) { artistResult in
            guard let artistResult = artistResult else { return }

            let artistID = artistResult.first?.id

            DispatchQueue.main.async {
                guard let artistID = artistID else { return }
                NetworkManager.shared.getRecommendations(with: token, artistID: artistID) { tracksResult in
                    guard let tracksResult = tracksResult else { return }
                    let trackURIsArray = tracksResult.map { $0.uri }
                    print(trackURIsArray)

                    DispatchQueue.main.async {
                        NetworkManager.shared.createPlaylist(with: token, songs: trackURIsArray, playlistName: playlistName) { playlist in
                            guard let playlist = playlist else { return }
                            print("playlist created:", playlist.name)

                            DispatchQueue.main.async {
                                guard let playlistImageURL = playlist.images.first?.url else { return }
                                NetworkManager.shared.downloadImage(from: playlistImageURL) { image in
                                    guard let image = image else { return }
                                    DispatchQueue.main.async {
                                        self.playlistImage.image = image
                                    }
                                }

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
    
    
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playlistTrackCell", for: indexPath)
        let playlistTrack = playlistTracks[indexPath.row]
        cell.textLabel?.text = playlistTrack.name
        cell.detailTextLabel?.text = playlistTrack.artists[0].name
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
