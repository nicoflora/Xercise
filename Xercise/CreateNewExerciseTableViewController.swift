//
//  CreateNewExerciseTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData
import Parse

class CreateNewExerciseTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var sectionTitles = [String]()
    var sectionTitlesAddingFromWorkout = [String]()
    var muscleGroups = [String]()
    var exerciseTitle = ""
    var exerciseMuscleGroup = ""
    var image = UIImage(named: "new_exercise_icon")
    var exerciseDescription = ""
    var heavyReps = -1
    var enduranceReps = -1
    var heavySets = -1
    var enduranceSets = -1
    var activityIndicator = UIActivityIndicatorView()
    let constants = XerciseConstants()
    let dataMgr = DataManager()
    var addingFromWorkout = false
    var unsavedData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sectionTitles = constants.newExerciseTitles
        sectionTitlesAddingFromWorkout = constants.newExerciseInWorkoutTitles
        muscleGroups = constants.muscleGroups
    }
    
    @IBAction func saveExercise(sender: AnyObject) {
        
        var dataValidated = false
        
        // Validate Data
        if exerciseTitle.characters.count > 3 {
            if image != UIImage(named: "new_exercise_icon"){
                if exerciseDescription != constants.exerciseDescriptionText {
                    if heavyReps != -1 && enduranceReps != -1 && heavySets != -1 && enduranceSets != -1 {

                        // All validations passed
                        dataValidated = true
                        
                        // Create identifier
                        let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil))
                        
                        if addingFromWorkout == false {
                        
                            if exerciseMuscleGroup != "" {
                                // Just adding a single exercise
                                // Prompt user for saving the exercise to the community or just on the device
                                let publicActionSheet = UIAlertController(title: nil, message: "Would you like to allow this exercise to be publicly accessible by other members of the community, or keep the exercise private?", preferredStyle: UIAlertControllerStyle.ActionSheet)
                                publicActionSheet.addAction(UIAlertAction(title: "Public", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                    
                                    // Save the exercise to the device and Parse DB
                                    if let img = UIImageJPEGRepresentation(self.image!, 0.5) {

                                        // Save to core data
                                        //self.displayActivityIndicator()
                                        self.dataMgr.saveExerciseToDevice(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                            //self.removeActivityIndicator()
                                            if success {
                                                // Saved to core data, now save to Parse
                                                // Save to Parse
                                                self.displayActivityIndicator()
                                                self.dataMgr.saveExerciseToParse(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                                    self.removeActivityIndicator()
                                                    if success {
                                                        // Present success alert and pop VC
                                                        self.presentSucessAlert()
                                                    } else {
                                                        // Saving to Core Data succeeded but Parse failed
                                                        let alert = UIAlertController(title: "Public Save Error", message: "Your exercise was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                                        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                                                        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                                            //try again
                                                            self.displayActivityIndicator()
                                                            self.dataMgr.saveExerciseToParse(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                                                self.removeActivityIndicator()
                                                                if success {
                                                                    // Save to Parse was successful
                                                                    self.presentSucessAlert()
                                                                } else {
                                                                    // Parse failed again
                                                                    let alert = UIAlertController(title: "Public Save Error", message: "Your exercise was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                                                    self.presentViewController(alert, animated: true, completion: nil)
                                                                }
                                                            })
                                                        }))
                                                        self.presentViewController(alert, animated: true, completion: nil)
                                                    }
                                                })
                                            } else {
                                                self.presentAlert("Error", message: "There was an error saving your exercise. Please try again")
                                            }
                                        })
                                    } else {
                                        self.presentAlert("Error", message: "There was an error with your image, please use a different one and try again.")
                                    }
                                }))
                                publicActionSheet.addAction(UIAlertAction(title: "Private", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                    
                                    // Save the exercise to Core Data only
                                    if let img = UIImageJPEGRepresentation(self.image!, 0.5) {
                                        //self.displayActivityIndicator()
                                        self.dataMgr.saveExerciseToDevice(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                            //self.removeActivityIndicator()
                                            if success {
                                                // Present success alert and pop VC
                                                self.presentSucessAlert()
                                            } else {
                                                self.presentAlert("Error", message: "There was an error saving your exercise. Please try again")
                                            }
                                        })
                                    } else {
                                        self.presentAlert("Error", message: "There was an error with your image, please use a different one and try again.")
                                    }
                                }))
                                publicActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                                self.presentViewController(publicActionSheet, animated: true, completion: nil)
                            }
                        } else {
                            // Adding an exercise inside of create workout
                            // Just save exercise to device
                            self.displayActivityIndicator()
                            if let img = UIImageJPEGRepresentation(self.image!, 0.5) {
                                self.dataMgr.saveExerciseToDevice(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                    self.removeActivityIndicator()
                                    if success {
                                        // Add to NSUserDefaults to get this exercise in Create New Workout
                                        let newEntry = Entry(exerciseTitle: self.exerciseTitle, exerciseIdentifer: uuid as String)
                                        self.dataMgr.storeEntriesInDefaults([newEntry], key: "addedExercise")
                                        // Present success alert and pop VC
                                        self.presentSucessAlert()
                                    } else {
                                        self.presentAlert("Error", message: "There was an error saving your exercise. Please try again")
                                    }
                                })
                            } else {
                                self.presentAlert("Error", message: "There was an error with your image, please use a different one and try again.")
                            }
                        }
                    }
                }
            }
        }
        
        if dataValidated == false {
            presentAlert("Error!", message: "There was an error in your exercise data. Please review your data and try again.")
        }
    }
    
    func displayActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.center = self.tableView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.backgroundColor = UIColor.grayColor()
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func removeActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if addingFromWorkout {
            return sectionTitlesAddingFromWorkout.count
        } else {
            return sectionTitles.count
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if addingFromWorkout {
            return sectionTitlesAddingFromWorkout[section]
        } else {
            return sectionTitles[section]
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGrayColor()
        let header = UITableViewHeaderFooterView()
        header.textLabel?.font = UIFont(name: "Marker Felt", size: 16)
        header.textLabel?.textColor = UIColor.blackColor()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if addingFromWorkout {
            return 1
        } else {
            if section == 1 {
                return muscleGroups.count
            } else {
                return 1
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if addingFromWorkout {
            switch indexPath.section {
            case 0: return 44
            case 1: return 54
            case 2: return 150
            case 3: return 85
            case 4: return 85
            default: return 44
            }
        } else {
            switch indexPath.section {
            case 0: return 44
            case 1: return 44
            case 2: return 54
            case 3: return 150
            case 4: return 85
            case 5: return 85
            default: return 44
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if addingFromWorkout {
            // If adding from a workout, do not display the muscle groups
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
                cell.title.tag = 1
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextFieldTextDidChangeNotification, object: nil)
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseImage", forIndexPath: indexPath) as! ExerciseImageTableViewCell
                cell.addImageButton.addTarget(self, action: "addImage:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.exerciseImage.image = image
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseDescription", forIndexPath: indexPath) as! ExerciseDescriptionTableViewCell
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextViewTextDidChangeNotification, object: nil)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseReps", forIndexPath: indexPath) as! ExerciseRepsTableViewCell
                cell.heavyStepper.tag = 0
                cell.enduranceStepper.tag = 1
                cell.heavyStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                cell.enduranceStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                return cell
            case 4:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseSets", forIndexPath: indexPath) as! ExerciseSetsTableViewCell
                cell.heavyStepper.tag = 2
                cell.enduranceStepper.tag = 3
                cell.heavyStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                cell.enduranceStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                return cell
            default:
                let cell = UITableViewCell()
                cell.textLabel?.text = "There was an error, please try reloading the page."
                return cell
            }
        } else {
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextFieldTextDidChangeNotification, object: nil)
                return cell
            case 1:
                let cell = UITableViewCell()
                cell.textLabel?.text = muscleGroups[indexPath.row]
                cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
                if exerciseMuscleGroup == muscleGroups[indexPath.row] {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseImage", forIndexPath: indexPath) as! ExerciseImageTableViewCell
                cell.addImageButton.addTarget(self, action: "addImage:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.exerciseImage.image = image
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseDescription", forIndexPath: indexPath) as! ExerciseDescriptionTableViewCell
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextViewTextDidChangeNotification, object: nil)
                return cell
            case 4:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseReps", forIndexPath: indexPath) as! ExerciseRepsTableViewCell
                cell.heavyStepper.tag = 0
                cell.enduranceStepper.tag = 1
                cell.heavyStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                cell.enduranceStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                return cell
            case 5:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseSets", forIndexPath: indexPath) as! ExerciseSetsTableViewCell
                cell.heavyStepper.tag = 2
                cell.enduranceStepper.tag = 3
                cell.heavyStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                cell.enduranceStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                return cell
            default:
                let cell = UITableViewCell()
                cell.textLabel?.text = "There was an error, please try reloading the page."
                return cell
            }
        }
    }
    
    func saveData(notif : NSNotification) {
        
        unsavedData = true
        
        if let textField = notif.object as? UITextField {
            // Saving title field
            exerciseTitle = textField.text!
        } else if let textView = notif.object as? UITextView {
            // Saving description field
            exerciseDescription = textView.text!
        }
    }
    
    func stepperValueChanged(sender: UIStepper) {
        switch sender.tag {
        case 0:
            heavyReps = Int(sender.value)
        case 1:
            enduranceReps = Int(sender.value)
        case 2:
            heavySets = Int(sender.value)
        case 3:
            enduranceSets = Int(sender.value)
        default:
            return
        }
    }
    
    func addImage(sender: UIButton) {
        // Allow user to add an image and update the exercise image
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = false
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        self.image = image
        tableView.reloadData()
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if addingFromWorkout == false && indexPath.section == 1 {
            // Deselct all other rows
            for i in 0...self.muscleGroups.count - 1{
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1))
                cell?.accessoryType = UITableViewCellAccessoryType.None
                
            }
            
            // Add checkmark to the selected row and store muscle group
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
            exerciseMuscleGroup = (cell?.textLabel?.text)!
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func presentAlert(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentSucessAlert() {
        let alert = UIAlertController(title: "Success", message: "Your exercise has been saved!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
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
