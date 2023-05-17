//
//  NewPlaylistViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 17/05/2023.
//

import UIKit

class NewPlaylistViewController: UIViewController {

    @IBOutlet weak var playlistImage: UIImageView!
    
    @IBOutlet weak var playlistTitle: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var playlistName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        guard let playlistName = playlistName else { return }
        playlistTitle.text = playlistName
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
