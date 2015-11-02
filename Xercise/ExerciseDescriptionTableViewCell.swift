//
//  ExerciseDescriptionTableViewCell.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class ExerciseDescriptionTableViewCell: UITableViewCell {

    @IBOutlet var exerciseDescription: UITextView!
    
    var exerciseDescriptionText : String {
        get {
            return exerciseDescription.text!
        }
        
        set(text) {
            exerciseDescription.text = text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let constants = XerciseConstants()
        
        exerciseDescription.text = constants.exerciseDescriptionText
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
