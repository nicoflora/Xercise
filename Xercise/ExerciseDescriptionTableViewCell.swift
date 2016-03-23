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
    let constants = XerciseConstants.sharedInstance
    
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
        exerciseDescription.text = constants.exerciseDescriptionText
        exerciseDescription.textColor = UIColor.lightGrayColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
