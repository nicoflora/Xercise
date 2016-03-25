//
//  ExerciseRepsTableViewCell.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class ExerciseRepsTableViewCell: UITableViewCell {

    
    @IBOutlet var heavyStepper: UIStepper!
    @IBOutlet var enduranceStepper: UIStepper!
    @IBOutlet var heavyReps: UILabel!
    @IBOutlet var enduranceReps: UILabel!
    var numberOfHeavyReps = -1
    var numberOfEnduranceReps = -1
    
    @IBAction func heavyStepperValueChanged(sender: UIStepper) {
        numberOfHeavyReps = Int(sender.value)
        heavyReps.text = Int(sender.value).description
    }
    
    @IBAction func enduranceStepperValueChanged(sender: UIStepper) {
        numberOfEnduranceReps = Int(sender.value)
        enduranceReps.text = Int(sender.value).description
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        heavyStepper.wraps = true
        heavyStepper.autorepeat = true
        heavyStepper.maximumValue = 30
        heavyStepper.value = 0
        heavyReps.text = "\(0)"
        
        enduranceStepper.wraps = true
        enduranceStepper.autorepeat = true
        enduranceStepper.maximumValue = 30
        enduranceStepper.value = 0
        enduranceReps.text = "\(0)"

        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
