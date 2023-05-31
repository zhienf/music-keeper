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
    
    @IBOutlet weak var minTempoTextField: UITextField!
    
    @IBOutlet weak var maxTempoTextField: UITextField!
    
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
    
    var token: String?
    weak var databaseController: DatabaseProtocol?
    var songsCount: Int?
    var librarySongs: [Track]?
    var initialValues: (Double, Double, Double) = (0, 0, 0)
    weak var delegate: MoodChangeDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // get a reference to the database from the appDelegate
        let appDelegate = (UIApplication.shared.delegate as? AppDelegate)
        databaseController = appDelegate?.databaseController
        
        // Retrieve the token from Core Data
        token = databaseController?.fetchAccessToken()
        let refreshToken = databaseController?.fetchRefreshToken()
        print("filter token:", token!)
        print("filter refresh token:", refreshToken)
        
        if let songsCount = songsCount {
            songsCountLabel.text = "\(songsCount) songs"
        }
        
        danceabilitySlider.setValue(Float(initialValues.0), animated: false)
        energySlider.setValue(Float(initialValues.1), animated: false)
        valenceSlider.setValue(Float(initialValues.2), animated: false)
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
