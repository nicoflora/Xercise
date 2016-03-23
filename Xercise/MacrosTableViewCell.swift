//
//  MacrosTableViewCell.swift
//  Xercise
//
//  Created by Nico Flora on 2/23/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit

class MacrosTableViewCell: UITableViewCell {
    
    @IBOutlet var mealName: UILabel!
    @IBOutlet var mealCarbs: UILabel!
    @IBOutlet var mealFats: UILabel!
    @IBOutlet var mealProteins: UILabel!
    @IBOutlet var percentageGoalAchievedView: UIView!
    @IBOutlet var percentageGoalAchievedViewConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
