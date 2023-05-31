//
//  FilterSongViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 29/05/2023.
//

import UIKit

protocol MoodChangeDelegate: AnyObject {
    func changedToValues(_ values: (Double, Double, Double))
    func resetValues()
}

class FilterSongViewController: UIViewController {

    @IBOutlet weak var songsCountLabel: UILabel!
    @IBOutlet weak var danceabilitySlider: UISlider!
    @IBOutlet weak var energySlider: UISlider!
    @IBOutlet weak var valenceSlider: UISlider!
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        let danceabilityValue = Double(danceabilitySlider.value)
        let energyValue = Double(energySlider.value)
        let valenceValue = Double(valenceSlider.value)
        
        delegate?.changedToValues((danceabilityValue, energyValue, valenceValue))
    }
    
    @IBAction func clearFilters(_ sender: Any) {
        danceabilitySlider.setValue(0.0, animated: false)
        energySlider.setValue(0.0, animated: false)
        valenceSlider.setValue(0.0, animated: false)
        
        delegate?.resetValues()
    }
    
    @IBAction func showResults(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // properties to retrieve access token for API calls
    var token: String?
    weak var databaseController: DatabaseProtocol?
    
    // properties for keeping track of sliders' values
    var initialValues: (Double, Double, Double) = (0, 0, 0)
    weak var delegate: MoodChangeDelegate?
    
    // properties for filtering library
    var songsCount: Int?
    var librarySongs: [Track]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        
        if let songsCount = songsCount {
            songsCountLabel.text = "\(songsCount) songs"
        }
        
        // initialise sliders' values
        danceabilitySlider.setValue(Float(initialValues.0), animated: false)
        energySlider.setValue(Float(initialValues.1), animated: false)
        valenceSlider.setValue(Float(initialValues.2), animated: false)
    }
}
