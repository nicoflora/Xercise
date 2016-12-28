//
//  MyXercisesTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData

protocol XercisesUpdatedDelegate {
    func updateXercises()
}

class MyXercisesTableViewController: UITableViewController, XercisesUpdatedDelegate {

    var workouts = [Entry]()
    var exercises = [Entry]()
    let dataMgr = DataManager.sharedInstance
    let constants = XerciseConstants.sharedInstance
    var selectedIndex : NSIndexPath?
    var activityIndicator = UIActivityIndicatorView()
    var exercisesByGroup = [ExercisesByMuscleGroup]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataMgr.updateXercisesDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        // Fetch data
        getMyXercises()
    }
    
    func updateXercises() {
        getMyXercises()
    }
    
    func getMyXercises() {
        workouts = dataMgr.getMyWorkouts()
        exercises = dataMgr.getMyExercises()
        sortByMuscleGroup(constants.muscleGroups)
        tableView.reloadData()
    }
    
    func sortByMuscleGroup(groups : [String]) {
        exercisesByGroup.removeAll()
        for currentMuscleGroup in groups {
            var exercisesForMuscle = [Entry]()
            for exercise in exercises {
                if exercise.muscle_group == currentMuscleGroup {
                    exercisesForMuscle.append(exercise)
                }
            }
            exercisesByGroup.append(ExercisesByMuscleGroup(muscleGroup: currentMuscleGroup, exercises : exercisesForMuscle))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Workouts"
        } else {
            if exercisesByGroup.count > 0 {
                return "\(exercisesByGroup[section - 1].muscleGroup) Exercises"
            } else {
                return "Exercises"
            }
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGrayColor()
        let header = UITableViewHeaderFooterView()
        header.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
        header.textLabel?.textColor = UIColor.blackColor()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if exercisesByGroup.count > 0 {
            return exercisesByGroup.count + 1
        } else {
            return 2
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if workouts.count == 0 {
                return 1
            } else {
                return workouts.count
            }
        } else {
            if exercisesByGroup[section - 1].exercises.count > 0 {
                return exercisesByGroup[section - 1].exercises.count
            } else {
                return 1
            }
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = UITableViewCell()
        if indexPath.section == 0 {
            if workouts.count > 0 {
                cell.textLabel?.text = workouts[indexPath.row].title
            } else {
                cell.textLabel?.text = "No workouts saved!"
                cell.selectionStyle = UITableViewCellSelectionStyle.None
            }
        } else {
            if exercisesByGroup[indexPath.section - 1].exercises.count > 0 {
                cell.textLabel?.text = exercisesByGroup[indexPath.section - 1].exercises[indexPath.row].title
            } else {
                cell.textLabel?.text = "No \(exercisesByGroup[indexPath.section - 1].muscleGroup) exercises saved!"
                cell.selectionStyle = UITableViewCellSelectionStyle.None
            }
            /*
            if exercises.count > 0 {
                cell.textLabel?.text = exercises[indexPath.row].title
            } else {
                cell.textLabel?.text = "No exercises saved!"
                cell.selectionStyle = UITableViewCellSelectionStyle.None
            }*/
        }
        cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
        return cell
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "New Workout", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Present VC to create a new workout
            self.performSegueWithIdentifier("newWorkout", sender: self)
        }))
        actionSheet.addAction(UIAlertAction(title: "New Exercise", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Present VC to create a new exercise
            self.performSegueWithIdentifier("newExercise", sender: self)
        }))
        actionSheet.addAction(UIAlertAction(title: "Add From Group Code", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Present alert to enter code and perform validation
            let alert = UIAlertController(title: "Enter Group Code", message: "Enter the group code for the workout you want to add.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                textField.placeholder = "Group Code"
                textField.autocorrectionType = UITextAutocorrectionType.No
                textField.tag = -1
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Add Workout", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                let textfield = alert.textFields![0] as UITextField
                if let text = textfield.text {
                    if text != "" {
                        // Validate that the group code doesn't contain a space to guard against invalid codes
                        if !text.containsString(" ") {
                            self.displayActivityIndicator()
                            self.dataMgr.getWorkoutFromDB(withID: text, completion: { (workout) in
                                self.removeActivityIndicator()
                                if let workout = workout {
                                    // Query was successful, retrieved a workout - save workout to Device
                                    self.dataMgr.queryForItemByID(workout.identifier, entityName: "Workout", completion: { (success) -> Void in
                                        if success {
                                            // Workout is already stored on device, don't save again
                                            self.presentAlert("Duplicate Save", alertMessage: "This workout has already been saved to this device!")
                                        } else {
                                            self.displayActivityIndicator()
                                            self.dataMgr.saveWorkoutToDevice(false, workoutName: workout.name, workoutMuscleGroup: workout.muscleGroup, id: workout.identifier, exerciseIDs: workout.exerciseIDs, publicWorkout: true, completion: { (success) -> Void in
                                                self.removeActivityIndicator()
                                                if success {
                                                    // Workout has been saved to device, add group code to device
                                                    self.displayActivityIndicator()
                                                    self.dataMgr.addGroupCodeByID(workout.identifier, code: text, completion: { (success) -> Void in
                                                        self.removeActivityIndicator()
                                                        if success {
                                                            // Group code added, now get the exercises from Parse
                                                            self.presentAlert("Success", alertMessage: "The workout added from a Group Code was sucessfully added to your My Xercises!")
                                                            self.getMyXercises()
                                                        } else {
                                                            self.presentAlert("Error", alertMessage: "There was an error adding your workout from a Group Code, please try again.")
                                                        }
                                                    })
                                                } else {
                                                    self.presentAlert("Error", alertMessage: "There was an error adding your workout from a Group Code, please try again.")
                                                }
                                            })
                                        }
                                    })
                                } else {
                                    self.presentAlert("Error", alertMessage: "There was an error adding your workout from a Group Code, please try again.")
                                }
                            })
                        } else {
                            self.presentAlert("Error", alertMessage: "There was an error adding your workout from a Group Code, please try again.")
                        }
                    }  else {
                        self.presentAlert("Error", alertMessage: "There was an error adding your workout from a Group Code, please try again.")
                    }
                } else {
                    self.presentAlert("Error", alertMessage: "There was an error adding your workout from a Group Code, please try again.")
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 {
            if workouts.count == 0 {
                return false
            } else {
                return true
            }
        } else {
            if exercisesByGroup.count >= indexPath.section - 1 {
                if exercisesByGroup[indexPath.section - 1].exercises.count > 0 {
                    return true
                }
            }
            return false
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Prompt the user for confirmation to the row from the data source
            if indexPath.section == 0 {
                presentConfirmAlert("Delete?", alertMessage: "Are you sure you want to delete this workout? This action cannot be undone.", confirmTitle: "Delete", completion: { (confirm) -> Void in
                    if confirm {
                        // Delete the workout
                        let idToDelete = self.workouts[indexPath.row].identifier
                        // Remove from core data
                        self.dataMgr.deleteItemByID(idToDelete, entityName: "Workout", completion: { (success) -> Void in
                            if success {
                                // Remove from local array
                                self.workouts.removeAtIndex(indexPath.row)
                                if self.workouts.count == 0 {
                                    tableView.reloadData()
                                } else {
                                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                                }

                            } else {
                                self.presentAlert("Error", alertMessage: "There was an issue deleting your workout, please try again!")
                            }
                        })
                    } else {
                        tableView.editing = false
                    }
                })
                
            } else {
                if exercisesByGroup.count >= indexPath.section - 1 {
                    if exercisesByGroup[indexPath.section - 1].exercises.count > 0 {
                        presentConfirmAlert("Delete?", alertMessage: "Are you sure you want to delete this exercise? This action cannot be undone.", confirmTitle: "Delete", completion: { (confirm) -> Void in
                            if confirm {
                                // Delete the exercise
                                let idToDelete = self.exercisesByGroup[indexPath.section - 1].exercises[indexPath.row].identifier
                                // Remove from core data
                                self.dataMgr.deleteItemByID(idToDelete, entityName: "Exercise", completion: { (success) -> Void in
                                    if success {
                                        // Remove from local array
                                        self.exercisesByGroup[indexPath.section - 1].exercises.removeAtIndex(indexPath.row)
                                        if self.exercisesByGroup[indexPath.section - 1].exercises.count == 0 {
                                            tableView.reloadData()
                                        } else {
                                            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                                        }
                                    } else {
                                        self.presentAlert("Error", alertMessage: "There was an issue deleting your exercise, please try again!")
                                    }
                                })
                            } else {
                                tableView.editing = false
                            }
                        })
                    }
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath
        if indexPath.section == 0 {
            if workouts.count > 0 {
                // Display workout
                self.performSegueWithIdentifier("displayWorkoutFromSaved", sender: self)
            }
        } else {
            if exercises.count > 0 {
            // Display an exercise
                if exercisesByGroup[indexPath.section - 1].exercises.count > 0 {
                    self.performSegueWithIdentifier("displayExerciseFromSaved", sender: self)
                }
            }
        }
    }
    
    func presentAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentConfirmAlert(alertTitle : String, alertMessage : String, confirmTitle : String, completion : (confirm : Bool) -> Void) {
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            completion(confirm: false)
        }))
        alert.addAction(UIAlertAction(title: confirmTitle, style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            completion(confirm: true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func displayActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.center = self.tableView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.backgroundColor = UIColor(hexString: "#0f3878") //UIColor.grayColor()
        activityIndicator.layer.cornerRadius = activityIndicator.bounds.width / 6
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func removeActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }


    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let index = selectedIndex else {return}
        if segue.identifier == "displayExerciseFromSaved" {
            let destinationVC = segue.destinationViewController as! DisplayExerciseTableViewController
            destinationVC.exerciseIdentifier = exercisesByGroup[index.section - 1].exercises[index.row].identifier
            destinationVC.hideRateFeatures = true
        } else if segue.identifier == "displayWorkoutFromSaved" {
            let destinationVC = segue.destinationViewController as! DisplayWorkoutTableViewController
            destinationVC.workoutIdentifier = workouts[index.row].identifier
            destinationVC.displayingFromSaved = true
        }
        // Reset selected index
        selectedIndex = nil
    }
    

}
