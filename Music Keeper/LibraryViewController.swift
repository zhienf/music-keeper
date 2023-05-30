//
//  LibraryViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MoodChangeDelegate {
    
    func changedToValue(_ value: Double) {
        moodValue = value
    }
    
    @IBAction func savePlaylistButton(_ sender: Any) {
        let overLayer = OverLayerPopUp()
        overLayer.songsCount = songList.count
        overLayer.songListToSave = songList
        overLayer.appear(sender: self)
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    @IBOutlet weak var songsCount: UILabel!
    
    private var songList: [Track] = []
    var token: String?
    weak var databaseController: DatabaseProtocol?
    var moodValue: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("library token:", token!)
        print("library refresh token:", refreshToken)
        
        fetchLibrary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewDidLoad()
    }
    
    private func fetchLibrary() {
        guard let token = token else { return }
        var allTracks: [Track] = [] // Array to store all fetched tracks
        let limit = 50
        var offset = 0
        
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
                // Example: Filtering songs within the range of moodValue ± 0.1
                if let moodValue = self.moodValue {
                    let filteredSongs = tracks.filter { savedTrack in
                        guard let audioFeature = audioFeaturesItems.first(where: { $0.id == savedTrack.id }) else {
                            return false
                        }
                        let lowerBound = moodValue - 0.1
                        let upperBound = moodValue + 0.1
                        return audioFeature.danceability >= lowerBound && audioFeature.danceability <= upperBound
                    }
                    completion(filteredSongs) // Return the filtered songs through the completion closure
                } else {
                    completion(tracks) // Return the original list of tracks
                }
            }
        }
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "librarySongCell", for: indexPath)
        let song = songList[indexPath.row]
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artists[0].name
        return cell
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
            destination.delegate = self
        }
    }
}
