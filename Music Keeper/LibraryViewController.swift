//
//  LibraryViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class LibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBAction func filterSongsButton(_ sender: Any) {
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        fetchLibrary()
    }
    
    private func fetchLibrary() {
        guard let token = token else { return }
//        NetworkManager.shared.getLibrary(with: token) { xResult in
//            guard let xResult = xResult else { return }
//            self.songList = xResult
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
//        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recentlyPlayedCell", for: indexPath)
//        let recentlyPlayedTrack = recentlyPlayedTracks[indexPath.row]
//        cell.textLabel?.text = recentlyPlayedTrack.track.name
//        cell.detailTextLabel?.text = recentlyPlayedTrack.track.artists[0].name
        return cell
    }
}
