//
//  ExerciseImageTableViewCell.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class ExerciseImageTableViewCell: UITableViewCell {

    
    @IBOutlet var exerciseImage: UIImageView!
    @IBOutlet var addImageButton: UIButton!
    
    
    /*@IBAction func addImageButtonPressed(sender: AnyObject) {
        
        // Allow user to add an image and update the exercise image
        let image = UIImagePickerController()
        //image.delegate =
        image.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        image.allowsEditing = false
        
        //CreateNewExerciseTableViewController.presentViewController(image, animated: true, completion: nil)

        
        // Change button title
        addImageButton.setTitle("Replace image", forState: UIControlState.Normal)
    }*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
