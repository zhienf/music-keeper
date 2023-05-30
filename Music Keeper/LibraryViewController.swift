//
//  LibraryViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MoodChangeDelegate {
    
    func changedToValue(_ value: Float) {
        moodValue = value
    }
    
    @IBAction func savePlaylistButton(_ sender: Any) {
        let overLayer = OverLayerPopUp()
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
    var moodValue: Float?
    
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
        print("mood value:", moodValue)
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
                    DispatchQueue.main.async {
                        self.songList = allTracks
                        self.songsCount.text = "\(allTracks.count) songs"
                        self.tableView.reloadData()
                        print(self.songList)
                        
                        self.fetchAudioFeatures(for: self.songList) { averageEnergy, averageValence, averageDanceability in
//                            print("Average energy: \(averageEnergy)")
//                            print("Average valence: \(averageValence)")
//                            print("danceability: \(averageDanceability)")
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
    
    private func fetchAudioFeatures(for tracks: [Track], completion: @escaping (Double, Double, Double) -> Void) {
        guard let token = token else { return }
        
        let trackIDs = tracks.map { $0.id }.joined(separator: ",")
        
        NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
            guard let audioFeaturesResult = audioFeaturesResult else { return }
            let audioFeaturesItems = audioFeaturesResult
            print(audioFeaturesItems)
            
            DispatchQueue.main.async {
                var totalEnergy: Double = 0
                var totalValence: Double = 0
                var totalDanceability: Double = 0
                
                for audioFeatures in audioFeaturesItems {
                    totalEnergy += audioFeatures.energy
                    totalValence += audioFeatures.valence
                    totalDanceability += audioFeatures.danceability
                }
                
                let averageEnergy = totalEnergy / Double(audioFeaturesItems.count)
                let averageValence = totalValence / Double(audioFeaturesItems.count)
                let averageDanceability = totalDanceability / Double(audioFeaturesItems.count)

                completion(averageEnergy, averageValence, averageDanceability)
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
