//
//  LibraryViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MoodChangeDelegate {
    
    func changedToValues(_ values: (Double, Double, Double)) {
        danceabilityValue = values.0
        energyValue = values.1
        valenceValue = values.2
        print(danceabilityValue)
        print(energyValue)
        print(valenceValue)
    }
    func resetValues() {
        danceabilityValue = nil
        energyValue = nil
        valenceValue = nil
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
    var danceabilityValue: Double?
    var energyValue: Double?
    var valenceValue: Double?
    var indicator = UIActivityIndicatorView()   // displays a spinning animation to indicate loading
    
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
        
        // Add a loading indicator view
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = UIColor.lightGray
        self.view.addSubview(indicator)
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor), indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        indicator.startAnimating()
        
        fetchLibrary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        songList = []
        self.tableView.reloadData()
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
                            self.indicator.stopAnimating()
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
    
//    private func filterSongsByAudioFeatures(_ tracks: [Track], completion: @escaping ([Track]) -> Void) {
//        guard let token = token else { return }
//
//        let trackIDs = tracks.map { $0.id }.joined(separator: ",")
//
//        NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
//            guard let audioFeaturesResult = audioFeaturesResult else { return }
//            let audioFeaturesItems = audioFeaturesResult
//
//            DispatchQueue.main.async {
//                // Example: Filtering songs based on danceability, energy, and valence
//                if let danceabilityValue = self.danceabilityValue,
//                   let energyValue = self.energyValue,
//                   let valenceValue = self.valenceValue {
//
//                    let filteredSongs = tracks.filter { savedTrack in
//                        guard let audioFeature = audioFeaturesItems.first(where: { $0.id == savedTrack.id }) else {
//                            return false
//                        }
//
//                        var danceabilityLowerBound = 0.0
//                        var danceabilityUpperBound = 1.0
//                        var energyLowerBound = 0.0
//                        var energyUpperBound = 1.0
//                        var valenceLowerBound = 0.0
//                        var valenceUpperBound = 1.0
//
//                        if danceabilityValue != 0.0 {
//                            danceabilityLowerBound = danceabilityValue - 0.2
//                            danceabilityUpperBound = danceabilityValue + 0.2
//                        }
//                        if energyValue != 0.0 {
//                            energyLowerBound = energyValue - 0.2
//                            energyUpperBound = energyValue + 0.2
//                        }
//                        if valenceValue != 0.0 {
//                            valenceLowerBound = valenceValue - 0.2
//                            valenceUpperBound = valenceValue + 0.2
//                        }
//
//                        return audioFeature.danceability >= danceabilityLowerBound && audioFeature.danceability <= danceabilityUpperBound &&
//                            audioFeature.energy >= energyLowerBound && audioFeature.energy <= energyUpperBound &&
//                            audioFeature.valence >= valenceLowerBound && audioFeature.valence <= valenceUpperBound
//                    }
//                    completion(filteredSongs) // Return the filtered songs through the completion closure
//                } else {
//                    completion(tracks) // Return the original list of tracks
//                }
//            }
//        }
//    }
    
    private func filterSongsByAudioFeatures(_ tracks: [Track], completion: @escaping ([Track]) -> Void) {
        guard let token = token else { return }
        
        let trackIDs = tracks.map { $0.id }.joined(separator: ",")
        
        NetworkManager.shared.getAudioFeatures(with: token, ids: trackIDs) { audioFeaturesResult in
            guard let audioFeaturesResult = audioFeaturesResult else { return }
            let audioFeaturesItems = audioFeaturesResult
            
            DispatchQueue.main.async {
                // Example: Filtering songs based on danceability, energy, and valence
                if let danceabilityValue = self.danceabilityValue,
                   let energyValue = self.energyValue,
                   let valenceValue = self.valenceValue {
                    print(danceabilityValue, energyValue, valenceValue)
                    let filteredSongs = tracks.filter { savedTrack in
                        guard let audioFeature = audioFeaturesItems.first(where: { $0.id == savedTrack.id }) else {
                            return false
                        }
                        
                        let (danceabilityLowerBound, danceabilityUpperBound) = self.calculateBounds(value: danceabilityValue)
                        let (energyLowerBound, energyUpperBound) = self.calculateBounds(value: energyValue)
                        let (valenceLowerBound, valenceUpperBound) = self.calculateBounds(value: valenceValue)
                        
                        return (danceabilityLowerBound...danceabilityUpperBound).contains(audioFeature.danceability) &&
                            (energyLowerBound...energyUpperBound).contains(audioFeature.energy) &&
                            (valenceLowerBound...valenceUpperBound).contains(audioFeature.valence)
                    }
                    completion(filteredSongs) // Return the filtered songs through the completion closure
                } else {
                    completion(tracks) // Return the original list of tracks
                }
            }
        }
    }
    
    func calculateBounds(value: Double) -> (lowerBound: Double, upperBound: Double) {
        var lowerBound = 0.0
        var upperBound = 1.0
        if value != 0.0 {
            print("not 0.0")
            lowerBound = value - 0.2
            upperBound = value + 0.2
        }
        return (lowerBound, upperBound)
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
            destination.initialValues = (danceabilityValue ?? 0, energyValue ?? 0, valenceValue ?? 0)
            destination.delegate = self
        }
    }
}
