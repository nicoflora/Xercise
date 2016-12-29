//
//  ExerciseTitleTableViewCell.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class ExerciseTitleTableViewCell: UITableViewCell {

    @IBOutlet var title: UITextField!
    
    var exerciseTitle : String {
        get {
            return title.text!
        }
        
        set(text) {
            title.text = text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
