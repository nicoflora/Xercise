//
//  CreateNewWorkoutTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/2/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData
import Parse

class CreateNewWorkoutTableViewController: UITableViewController, UITabBarControllerDelegate {
    
    var exercises = [Entry]()
    let defaults = NSUserDefaults.standardUserDefaults()
    let constants = XerciseConstants()
    var sectionTitles = [String]()
    var muscleGroups = [MuscleGroup]()
    let dataMgr = DataManager()
    var workoutMuscleGroup = [String]()
    var workoutName = ""
    var activityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        sectionTitles = constants.newWorkoutTitles
        muscleGroups = constants.muscleGroupsArray
        defaults.removeObjectForKey("workoutExercises")
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Get previously made entries
        exercises = dataMgr.retrieveEntriesFromDefaults("workoutExercises")
        let newExercise = dataMgr.retrieveEntriesFromDefaults("addedExercise")
        if newExercise.count > 0 {
            // exercise added to workout
            for newEx in newExercise {
                exercises.append(newEx)
            }
            defaults.removeObjectForKey("addedExercise")
        }
        let addedSavedExercises = dataMgr.retrieveEntriesFromDefaults("exercisesToAdd")
        if addedSavedExercises.count > 0 {
            for savedExercise in addedSavedExercises {
                exercises.append(savedExercise)
            }
            defaults.removeObjectForKey("exercisesToAdd")
        }
        tableView.reloadData()
        self.tabBarController?.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.tabBarController?.delegate = nil
    }
    
    func getMyXercises(id : String) {
        exercises.append(dataMgr.getEntryByID(id, entityName: "Exercise")!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addExerciseButtonPressed(sender: AnyObject) {
        
        // Present action sheet to determine how to add exercise
        let actionSheet = UIAlertController(title: nil, message: "Would you like to create a new exercise or add one from My Xercises?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Create New", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Validate that the muscle group has been selected
            if self.workoutMuscleGroup.count > 0 {
                self.performSegueWithIdentifier("newExerciseFromWorkout", sender: self)
            } else {
                self.presentAlert("Error!", alertMessage: "Please select a muscle group before adding a new exercise")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Add from My Xercises", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.performSegueWithIdentifier("addFromSaved", sender: self)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "newExerciseFromWorkout" {
            let destinationVC = segue.destinationViewController as! CreateNewExerciseTableViewController
            destinationVC.addingFromWorkout = true
            destinationVC.exerciseMuscleGroup = workoutMuscleGroup
            dataMgr.storeEntriesInDefaults(exercises, key: "workoutExercises")
        } else if segue.identifier == "addFromSaved" {
            dataMgr.storeEntriesInDefaults(exercises, key: "workoutExercises")
        }
    }
    
    @IBAction func saveWorkoutButtonPressed(sender: AnyObject) {
        
        // Confirm that there is at least 1 exercise in the workout
        if exercises.count > 0 {
            // Confirm that the workout name has at least 3 characters
            if workoutName.characters.count > 2 {
                
                if workoutMuscleGroup.count > 0 {
                
                // Get list of identifiers for each exercise and archive the array for storage
                var ids = [String]()
                var names = [String]()
                for ex in exercises {
                    ids.append(ex.identifier)
                    names.append(ex.title)
                }
                //let exerciseIDs = dataMgr.archiveArray(ids)
                
                // Generate workout UUID
                let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil))
                
                // Present action sheet to determine if the workout is public or not and save appropriately
                let actionSheet = UIAlertController(title: nil, message: "Would you like to allow this workout to be publicly accessible by other members of the community, or keep the workout private? (Note, to share this exercise with others using a group code, the workout must be made public)", preferredStyle: UIAlertControllerStyle.ActionSheet)
                actionSheet.addAction(UIAlertAction(title: "Public", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    // Save to both device and Parse databases
                    
                    self.dataMgr.saveWorkoutToDevice(self.workoutName, workoutMuscleGroup: self.workoutMuscleGroup, id: uuid as String, exerciseIDs: ids, publicWorkout: true, completion: { (success) -> Void in
                        if success {
                            // Saving to core data was successful, now try Parse
                            self.displayActivityIndicator()
                            self.dataMgr.saveWorkoutToParse(self.workoutName, workoutMuscleGroup: self.workoutMuscleGroup, id: uuid as String, exerciseIDs: ids, exerciseNames: names, completion: { (success, identifier) -> Void in
                                self.removeActivityIndicator()
                                if success {
                                    // Save to Parse was successful
                                    // Check to make sure all referenced exercises are in Parse if made public
                                    self.displayActivityIndicator()
                                    self.dataMgr.checkParseExerciseAvailablity(ids, completion: { (success) -> Void in
                                        self.removeActivityIndicator()
                                        if success {
                                            // Remove exercises from defaults on success
                                            self.defaults.removeObjectForKey("workoutExercises")
                                            //self.presentSucessAlert()
                                            self.navigationController?.popViewControllerAnimated(true)
                                        }
                                    })
                                } else {
                                    // Saving to Core Data succeeded but Parse failed
                                    let publicAlert = UIAlertController(title: "Public Save Error", message: "Your workout was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                    publicAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                                    publicAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                        //try again
                                        self.dataMgr.saveWorkoutToParse(self.workoutName, workoutMuscleGroup: self.workoutMuscleGroup, id: uuid as String, exerciseIDs: ids, exerciseNames: names, completion: { (success, identifier) -> Void in
                                            if success == true {
                                                // Save to Parse was successful
                                                // Check to make sure all referenced exercises are in Parse if made public
                                                self.dataMgr.checkParseExerciseAvailablity(ids, completion: { (success) -> Void in
                                                    if success {
                                                        // Remove exercises from defaults on success
                                                        self.defaults.removeObjectForKey("workoutExercises")
                                                        //self.presentSucessAlert()
                                                        self.navigationController?.popViewControllerAnimated(true)
                                                    }
                                                })
                                            } else {
                                                // Saving to Core Data succeeded but Parse failed
                                                let alert = UIAlertController(title: "Public Save Error", message: "Your workout was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                                self.presentViewController(alert, animated: true, completion: nil)
                                            }
                                        })
                                    }))
                                    self.presentViewController(publicAlert, animated: true, completion: nil)
                                }
                            })
                        } else {
                            self.presentAlert("Error", alertMessage: "There was an error saving your workout. Please try again")
                        }
                    })

                }))
                actionSheet.addAction(UIAlertAction(title: "Private", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    // Save to device database only
                    self.dataMgr.saveWorkoutToDevice(self.workoutName, workoutMuscleGroup: self.workoutMuscleGroup, id: uuid as String, exerciseIDs: ids, publicWorkout: false, completion: { (success) -> Void in
                        if success {
                            // Remove exercises from defaults on success
                            self.defaults.removeObjectForKey("workoutExercises")

                            // Present success alert and pop VC
                            //self.presentSucessAlert()
                            self.navigationController?.popViewControllerAnimated(true)
                        } else {
                            self.presentAlert("Error", alertMessage: "There was an error saving your workout. Please try again")
                        }
                    })
                }))
                actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(actionSheet, animated: true, completion: nil)
                    
                } else {
                    presentAlert("No Muscle Group", alertMessage: "This workout does not have a muscle group. Please select one before saving.")
                }
            } else {
                presentAlert("No Name", alertMessage: "This workout does not have a name. Please name it before saving.")
            }
        } else {
            // Show error alert
            presentAlert("No Exercises", alertMessage: "There are no exercises in this workout. Please add at least one exercise before saving.")
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
    
    func presentAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentSucessAlert() {
        let alert = UIAlertController(title: "Success", message: "Your workout has been saved!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentLeaveScreenAlert(completion : (leave : Bool) -> Void) {
        let alert = UIAlertController(title: "Leave Screen?", message: "Leaving this current screen without saving will result in your unsaved workout to be lost, are you sure you want to leave?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            completion(leave: false)
        }))
        alert.addAction(UIAlertAction(title: "Leave", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            completion(leave: true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Tab bar controller delegate
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        // If the My Xercises Tab is selected, prompt the user of data loss before leaving the screen
        if exercises.count > 0 && viewController.tabBarItem.tag == 1 {
            presentLeaveScreenAlert({ (leave) -> Void in
                if leave {
                    // Leave page confirmed, remove exercises then go back to My Xercises page (root view controller)
                    self.defaults.removeObjectForKey("workoutExercises")
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            })
            return false
        } else {
            return true
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGrayColor()
        let header = UITableViewHeaderFooterView()
        header.textLabel?.font = UIFont(name: "Marker Felt", size: 16)
        header.textLabel?.textColor = UIColor.blackColor()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return  1
        } else if section == 1 {
            return muscleGroups.count
        } else {
            if exercises.count > 0 {
                return exercises.count
            } else {
                return 1
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
        
        if indexPath.section == 0 {
            let titleCell = tableView.dequeueReusableCellWithIdentifier("workoutTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
            titleCell.title.tag = 0
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextFieldTextDidChangeNotification, object: nil)
            return titleCell
        } else if indexPath.section == 1 {
            cell.textLabel?.text = muscleGroups[indexPath.row].mainGroup
            if workoutMuscleGroup.contains(muscleGroups[indexPath.row].mainGroup){
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            return cell
        } else {
            if exercises.count > 0 {
                cell.textLabel?.text = exercises[indexPath.row].title
            } else {
                cell.textLabel?.text = "No exercises in this workout!"
            }
            return cell
        }
    }
    
    func saveData(notif : NSNotification) {
        if let textField = notif.object as? UITextField {
            // Saving name field
            if textField.tag == 0 {
                workoutName = textField.text!
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            // Deselct all other rows
            for i in 0...self.muscleGroups.count - 1{
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1))
                cell?.accessoryType = UITableViewCellAccessoryType.None
            }
            
            // Add checkmark to the selected row and store muscle group
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
            workoutMuscleGroup.append((cell?.textLabel?.text)!)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 2 {
            if exercises.count > 0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            exercises.removeAtIndex(indexPath.row)
            // Update view
            if self.exercises.count == 0 {
                tableView.reloadData()
            } else {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }

        }
    }
}
