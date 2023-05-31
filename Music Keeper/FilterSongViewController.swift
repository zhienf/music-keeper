//
//  FilterSongViewController.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 29/05/2023.
//
// References:
// 1) FIT3178 Week 2 Lab Exercise - Sliders

import UIKit

protocol MoodChangeDelegate: AnyObject {
    func changedToValues(_ values: (Double, Double, Double))
    func resetValues()
}

/**
 A view controller that allows filters to be applied to user's liked songs library.

 This class is a subclass of UIViewController.

 Usage:
 1. Apply filters to liked songs library using sliders for danceability, energy and valence
 */
class FilterSongViewController: UIViewController {

    @IBOutlet weak var songsCountLabel: UILabel!
    @IBOutlet weak var danceabilitySlider: UISlider!
    @IBOutlet weak var energySlider: UISlider!
    @IBOutlet weak var valenceSlider: UISlider!
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        /**
         Detects if there is a change in any of the three sliders and informs its delegate.
         */
        let danceabilityValue = Double(danceabilitySlider.value)
        let energyValue = Double(energySlider.value)
        let valenceValue = Double(valenceSlider.value)
        
        delegate?.changedToValues((danceabilityValue, energyValue, valenceValue))
    }
    
    @IBAction func clearFilters(_ sender: Any) {
        /**
         Resets slider values to 0 when clear all button is selected and informs its delegate.
         */
        danceabilitySlider.setValue(0.0, animated: false)
        energySlider.setValue(0.0, animated: false)
        valenceSlider.setValue(0.0, animated: false)
        
        delegate?.resetValues()
    }
    
    @IBAction func showResults(_ sender: Any) {
        /**
         Return to previous view controller when show results button is selected
         */
        navigationController?.popViewController(animated: true)
    }
    
    // properties for keeping track of sliders' values
    var initialValues: (Double, Double, Double) = (0, 0, 0)
    weak var delegate: MoodChangeDelegate?
    
    // properties for filtering library
    var songsCount: Int?
    var librarySongs: [Track]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if let songsCount = songsCount {
            songsCountLabel.text = "\(songsCount) songs"
        }
        
        // initialise sliders' values
        danceabilitySlider.setValue(Float(initialValues.0), animated: false)
        energySlider.setValue(Float(initialValues.1), animated: false)
        valenceSlider.setValue(Float(initialValues.2), animated: false)
    }
}
