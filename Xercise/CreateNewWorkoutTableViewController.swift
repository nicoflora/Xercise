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

class CreateNewWorkoutTableViewController: UITableViewController {
    
    var exercises = [Entry]()
    let defaults = NSUserDefaults.standardUserDefaults()
    let constants = XerciseConstants()
    var sectionTitles = [String]()
    var muscleGroups = [String]()
    let dataMgr = DataManager()
    var workoutMuscleGroup = ""
    var workoutName = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        sectionTitles = constants.newWorkoutTitles
        muscleGroups = constants.muscleGroups
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
            if self.workoutMuscleGroup != "" {
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
            
            // Get list of identifiers for each exercise and archive the array for storage
            var ids = [String]()
            for ex in exercises {
                ids.append(ex.identifier)
            }
            let exerciseIDs = dataMgr.archiveArray(ids)
            
            // Generate workout UUID
            let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil))
            
            // Present action sheet to determine if the workout is public or not and save appropriately
            let actionSheet = UIAlertController(title: nil, message: "Would you like to allow this workout to be publicly accessible by other members of the community, or keep the workout private? (Note, to share this exercise with others using a group code, the workout must be made public)", preferredStyle: UIAlertControllerStyle.ActionSheet)
            actionSheet.addAction(UIAlertAction(title: "Public", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                // Save to both device and Parse databases
                
                self.saveToDevice(uuid as String, exerciseIDs: exerciseIDs,completion: { (success) -> Void in
                    if success {
                        
                        // Saving to core data was successful, now try Parse
                        self.saveToParse(uuid as String, exerciseIDs: exerciseIDs, completion: { (success) -> Void in
                            if success {
                                // Save to Parse was successful
                                // Check to make sure all referenced exercises are in Parse if made public
                                self.checkExerciseAvailablity(ids, completion: { (success) -> Void in
                                    if success {
                                        // Remove exercises from defaults on success
                                        self.defaults.removeObjectForKey("workoutExercises")
                                        self.presentSucessAlert()
                                    }
                                })
                            } else {
                                // Saving to Core Data succeeded but Parse failed
                                let publicAlert = UIAlertController(title: "Public Save Error", message: "Your workout was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                publicAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                                publicAlert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                    //try again
                                    self.saveToParse(uuid as String, exerciseIDs: exerciseIDs, completion: { (success) -> Void in
                                        if success == true {
                                            // Save to Parse was successful
                                            // Check to make sure all referenced exercises are in Parse if made public
                                            self.checkExerciseAvailablity(ids, completion: { (success) -> Void in
                                                if success {
                                                    // Remove exercises from defaults on success
                                                    self.defaults.removeObjectForKey("workoutExercises")
                                                    self.presentSucessAlert()
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
                self.saveToDevice(uuid as String, exerciseIDs: exerciseIDs, completion: { (success) -> Void in
                    if success {
                        // Remove exercises from defaults on success
                        self.defaults.removeObjectForKey("workoutExercises")

                        // Present success alert and pop VC
                        self.presentSucessAlert()
                    } else {
                        self.presentAlert("Error", alertMessage: "There was an error saving your workout. Please try again")
                    }
                })
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(actionSheet, animated: true, completion: nil)
            
        } else {
            // Show error alert
            presentAlert("Error", alertMessage: "There are no exercises in this workout. Please add at least one exercise before saving.")
        }
    }
    
    func checkExerciseAvailablity(ids : [String], completion : (success : Bool) -> Void) {
        var completionSuccess = true
        for exerciseID in ids {
            print(ids)
            let query = PFQuery(className: "Exercise")
            query.whereKey("identifier", equalTo: exerciseID)
            query.findObjectsInBackgroundWithBlock({ (objects : [PFObject]?, error: NSError?) -> Void in
                if objects?.count == 0 {
                    // Not in Parse database, add to Parse
                    if let exerciseToAdd : Exercise = self.dataMgr.getExerciseByID(exerciseID) {
                        // Got Exercise from Core Data - now add to Parse
                        if let img = UIImageJPEGRepresentation(exerciseToAdd.image, 0.5) {
                            self.dataMgr.saveExerciseToParse(exerciseToAdd.name, id: exerciseToAdd.identifier, muscleGroup: exerciseToAdd.muscleGroup, image: img, exerciseDescription: exerciseToAdd.description, completion: { (success) -> Void in
                                if success == false {
                                    // erorr saving to Parse
                                    completionSuccess = false
                                }
                            })
                        }
                    }
                }
            })
        }
        if completionSuccess {
            completion(success: true)
        } else {
            completion(success: false)
        }
    }
    
    func saveToDevice(id : String, exerciseIDs : NSData, completion : (success : Bool) -> Void) {
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext
        
        let newWorkout = NSEntityDescription.insertNewObjectForEntityForName("Workout", inManagedObjectContext: context)
        newWorkout.setValue(workoutName, forKey: "name")
        newWorkout.setValue(id, forKey: "identifier")
        newWorkout.setValue(exerciseIDs, forKey: "exercise_ids")
        newWorkout.setValue(workoutMuscleGroup, forKey: "muscle_group")
        
        do {
            //self.displayActivityIndicator()
            try context.save()
            completion(success: true)
            //self.displayActivityIndicator()
        } catch {
            //self.displayActivityIndicator()
            completion(success: false)
            print("There was an error saving the workout")
        }
    }
    
    func saveToParse(id : String, exerciseIDs : NSData, completion : (success : Bool) -> Void) {
        
        // Create Parse object to save
        let workout = PFObject(className: "Workout")
        
        workout["name"] = workoutName
        workout["identifier"] = id
        workout["exercise_ids"] = exerciseIDs
        workout["muscle_group"] = workoutMuscleGroup
        
        //self.displayActivityIndicator()
            
        workout.saveInBackgroundWithBlock { (success, error) -> Void in
            //self.displayActivityIndicator()
            if error == nil {
                
                self.presentSucessAlert()
                completion(success: true)

            } else {
                completion(success: false)
                self.presentAlert("Error", alertMessage: "There was an error saving your workout, please try again.")
            }
        }
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
            cell.textLabel?.text = muscleGroups[indexPath.row]
            if muscleGroups[indexPath.row] == workoutMuscleGroup {
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
            workoutMuscleGroup = (cell?.textLabel?.text)!
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
            tableView.reloadData()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}
