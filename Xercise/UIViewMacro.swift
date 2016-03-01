//
//  UIViewMacro.swift
//  Xercise
//
//  Created by Nico Flora on 2/27/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit

class UIViewMacro: UIView {

    @IBOutlet var mealName: UITextField!
    @IBOutlet var mealCarbs: UITextField!
    @IBOutlet var mealFats: UITextField!
    @IBOutlet var mealProteins: UITextField!
    var updateRow : Int?
    @IBOutlet var saveMealButton: UIButton!
    @IBOutlet var popUpTitle: UILabel!
   
    @IBOutlet var mealNameLabel: UILabel!

    @IBOutlet var mealNameHeight: NSLayoutConstraint!
    @IBOutlet var mealNameTextBoxHeight: NSLayoutConstraint!
    @IBOutlet var cancelMealButton: UIButton!
}
