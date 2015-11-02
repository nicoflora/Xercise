//
//  ExerciseSetsTableViewCell.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class ExerciseSetsTableViewCell: UITableViewCell {
    
    
    @IBOutlet var heavySets: UILabel!
    @IBOutlet var enduranceSets: UILabel!
    @IBOutlet var heavyStepper: UIStepper!
    @IBOutlet var enduranceStepper: UIStepper!
    
    
    var heavySetCount : Int {
        get {
            return Int(heavyStepper.value)
        }
    }
    
    var enduranceSetCount : Int {
        get {
            return Int(enduranceStepper.value)
        }
    }
    
    @IBAction func heavyStepperValueChanged(sender: UIStepper) {
        heavySets.text = Int(sender.value).description
    }
    
    @IBAction func enduranceStepperValueChanged(sender: UIStepper) {
        enduranceSets.text = Int(sender.value).description
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        heavyStepper.wraps = true
        heavyStepper.autorepeat = true
        heavyStepper.maximumValue = 15
        heavyStepper.value = 0
        heavySets.text = "\(0)"
        
        enduranceStepper.wraps = true
        enduranceStepper.autorepeat = true
        enduranceStepper.maximumValue = 15
        enduranceStepper.value = 0
        enduranceSets.text = "\(0)"
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
