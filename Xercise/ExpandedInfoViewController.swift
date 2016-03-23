//
//  HelpViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 10/31/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class ExpandedInfoViewController: UIViewController {
    
    var infoCategories = [String]()
    var selectedCategory = -1
    @IBOutlet var infoLabel: UITextView!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let constants = XerciseConstants.sharedInstance
        infoCategories = constants.infoCategories
        if selectedCategory != -1 {
            self.navigationItem.title = infoCategories[selectedCategory]
            titleLabel.text = infoCategories[selectedCategory]
            switch selectedCategory {
            case 0: infoLabel.text = constants.heavyInfo
            case 1: infoLabel.text = constants.enduranceInfo
            case 2: infoLabel.text = constants.macroInfo
            default: infoLabel.text = "There was an error getting your info, please go back and try again!"
            }
            infoLabel.font = UIFont(name: "Marker Felt", size: 21)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
