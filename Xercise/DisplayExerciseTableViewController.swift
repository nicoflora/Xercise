//
//  DisplayExerciseTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/7/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Parse

class DisplayExerciseTableViewController: UITableViewController {

    var exerciseIdentifier = ""
    var exerciseTitle = ""
    var hideRateFeatures = false
    let dataMgr = DataManager()
    let constants = XerciseConstants()
    var titles = [String]()
    var exerciseToDisplay = Exercise(name: "", muscleGroup: "", identifier: "", description: "", image: UIImage())
    var displayingGeneratedExercise = false
    @IBOutlet var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titles = constants.displayExerciseTitles
        
        if exerciseIdentifier != "" {
            // Retrieve the exercise from Core Data using the passed identifier
            let retrievedExercise = dataMgr.getExerciseByID(exerciseIdentifier)
            
            // If a non-nil exercise was returned, populate the appropriate fields
            if let exercise = retrievedExercise {
                exerciseToDisplay = exercise
            } else {
                // Couldn't fetch the exercise, nothing to display - present error and pop VC
                displayErrorAlert()
            }
        } else if !displayingGeneratedExercise {
        
            // No exercise identifier, nothing to display - present error and pop VC
            displayErrorAlert()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        // Reset variable to hide rate features
        hideRateFeatures = false
    }
    
    func changeExercise(identifier : String) {
        if identifier != "" {
            // Retrieve the exercise from Core Data using the passed identifier
            let retrievedExercise = dataMgr.getExerciseByID(identifier)
            
            // If a non-nil exercise was returned, populate the appropriate fields
            if let exercise = retrievedExercise {
                exerciseToDisplay = exercise
                tableView.reloadData()
            }
        }
    }
    
    func imageResize(imageObj:UIImage, sizeChange:CGSize)-> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        // If displaying from a generated exercise, this will generate a new exercise
        
        // If displaying from a generated/saved workout, this will display the next exercise in the workout
    }
    
    
    func shareAction() {
        // Share button pressed
        let shareActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        if displayingGeneratedExercise {
            shareActionSheet.addAction(UIAlertAction(title: "Save Exercise", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                // Save to device
                // Check if the exercise already exists
                self.dataMgr.queryForItemByID(self.exerciseToDisplay.identifier, entityName: "Exercise", completion: { (success) -> Void in
                    if success {
                        // Exercise is already saved, alert user of this
                        self.presentAlert("Already Saved", message: "This exercise has already been saved in your 'My Xercises' page.")
                    } else {
                        // Exercise has not been saved to device, save it
                        // Convert image
                        if let img = UIImageJPEGRepresentation(self.exerciseToDisplay.image, 0.5) {
                            // Save exercise to device
                            self.dataMgr.saveExerciseToDevice(self.exerciseToDisplay.name, id: self.exerciseToDisplay.identifier, muscleGroup: self.exerciseToDisplay.muscleGroup, image: img, exerciseDescription: self.exerciseToDisplay.description, completion: { (success) -> Void in
                                if success {
                                    self.presentAlert("Success", message: "The exercise has been saved to 'My Xercises'!")
                                } else {
                                    self.presentAlert("Error", message: "There was a problem saving this exercise, please try again.")
                                }
                            })
                        } else {
                            self.presentAlert("Error", message: "There was a problem saving this exercise, please try again.")
                        }

                    }
                })
            }))
        }
        shareActionSheet.addAction(UIAlertAction(title: "Share to Facebook", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            /* Will be completed in Sprint 5 - Use Case 5.3 */
            // Share to Facebook
        }))
        shareActionSheet.addAction(UIAlertAction(title: "Share to Twitter", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            /* Will be completed in Sprint 5 - Use Case 5.2 */
            // Share to Twitter
        }))
        shareActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(shareActionSheet, animated: true, completion: nil)
    }
    
    func thumbsDownRate() {
        // Call to Parse Cloud Code to rate an exercise with a thumbs down
        let rateDictionary = ["type" : "Exercise", "id" : exerciseToDisplay.identifier, "rating" : "thumbs_Down_Rate"]
        PFCloud.callFunctionInBackground("rate", withParameters: rateDictionary) { (object, error) -> Void in
            if error == nil {
                self.rateCompleted()
            } else {
                print("Error: \(error!.localizedDescription)")
            }
        }
    }
    
    func thumbsUpRate() {
        // Call to Parse Cloud Code to rate an exercise with a thumbs up
        let rateDictionary = ["type" : "Exercise", "id" : exerciseToDisplay.identifier, "rating" : "thumbs_Up_Rate"]
        PFCloud.callFunctionInBackground("rate", withParameters: rateDictionary) { (object, error) -> Void in
            if error == nil {
                self.rateCompleted()
            } else {
                print("Error: \(error!.localizedDescription)")
            }
        }
    }
    
    func rateCompleted() {
        // Make UI changes to the thumbs up and thumbs down rate buttons
        hideRateFeatures = true
        tableView.reloadData()
    }
    
    func presentAlert(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func displayErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "There was an error loading your exercise. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 44
        case 1:
            return 44
        case 2:
            return 230
        case 3:
            return 170
        case 4:
            return 90
        default:
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell()
            cell.textLabel?.text = exerciseToDisplay.name
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 1:
            let cell = UITableViewCell()
            cell.textLabel?.text = "Muscle Group: \(exerciseToDisplay.muscleGroup)"
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 15)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("displayExerciseImage", forIndexPath: indexPath) as! DisplayExerciseImageTableViewCell
            cell.exerciseImage.image = imageResize(exerciseToDisplay.image, sizeChange: cell.exerciseImage.frame.size)
            return cell
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("displayExerciseDescription", forIndexPath: indexPath) as! DisplayExerciseDescriptionTableViewCell
            cell.exerciseDescription.text = exerciseToDisplay.description
            cell.exerciseDescription.textAlignment = NSTextAlignment.Center
            cell.exerciseDescription.font = UIFont(name: "Marker Felt", size: 15)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCellWithIdentifier("displayExerciseShare", forIndexPath: indexPath) as! DisplayExerciseShareTableViewCell
            cell.shareButton.addTarget(self, action: "shareAction", forControlEvents: UIControlEvents.TouchUpInside)
            
            if hideRateFeatures {
                cell.thumbsDownRate.enabled = false
                cell.thumbsDownRate.hidden = true
                cell.thumbsUpRate.enabled = false
                cell.thumbsUpRate.hidden = true
            } else {
                cell.thumbsDownRate.enabled = true
                cell.thumbsDownRate.hidden = false
                cell.thumbsUpRate.enabled = true
                cell.thumbsUpRate.hidden = false
                cell.thumbsDownRate.addTarget(self, action: "thumbsDownRate", forControlEvents: UIControlEvents.TouchUpInside)
                cell.thumbsUpRate.addTarget(self, action: "thumbsUpRate", forControlEvents: UIControlEvents.TouchUpInside)
            }
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }
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
