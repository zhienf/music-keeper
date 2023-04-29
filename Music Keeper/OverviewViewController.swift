//
//  OverviewViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 28/04/2023.
//

import UIKit

class OverviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tableFooterView = UIView()
        }
    }
    
    private var artists: [Artist] = []
    var token: String?
    
    weak var databaseController: DatabaseProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        print("overview token:", token!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        fetchArtists()
    }
    
    private func fetchArtists() {
        guard let token = token else { return }
        NetworkManager.shared.getArtists(with: token) { artistResult in
            guard let artistResult = artistResult else { return }
            self.artists = artistResult.items
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    
// MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "librarySongCell", for: indexPath)
//        cell.contentView.backgroundColor = .black
        var content = cell.defaultContentConfiguration()
        let artist = artists[indexPath.row]
        content.text = artist.name
        content.textProperties.color = .white
        cell.contentConfiguration = content
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
