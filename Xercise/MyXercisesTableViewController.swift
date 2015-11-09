//
//  MyXercisesTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData

class MyXercisesTableViewController: UITableViewController {

    var workouts = [Entry]()
    var exercises = [Entry]()
    let dataMgr = DataManager()
    var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        // Fetch data
        getMyXercises()
        tableView.reloadData()
    }
    
    
    func getMyXercises() {
        workouts = dataMgr.getMyWorkouts()
        exercises = dataMgr.getMyExercises()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Workouts"
        } else if section == 1 {
            return "Exercises"
        } else {
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGrayColor()
        
        let header = UITableViewHeaderFooterView()
        header.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
        header.textLabel?.textColor = UIColor.blackColor()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if workouts.count == 0 {
                return 1
            } else {
                return workouts.count
            }
        } else if section == 1 {
            if exercises.count == 0 {
                return 1
            } else {
                return exercises.count
            }
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = UITableViewCell()

        if indexPath.section == 0 {
            if workouts.count > 0 {
                cell.textLabel?.text = workouts[indexPath.row].title
            } else {
                cell.textLabel?.text = "No workouts saved!"
            }
        } else if indexPath.section == 1 {
            if exercises.count > 0 {
                cell.textLabel?.text = exercises[indexPath.row].title
            } else {
                cell.textLabel?.text = "No exercises saved!"
            }
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
        actionSheet.addAction(UIAlertAction(title: "Add From Code", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Present alert to enter code and perform validation
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
                                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                            } else {
                                self.presentAlert("Error", alertMessage: "There was an issue deleting your workout, please try again!")
                            }
                        })
                    } else {
                        tableView.editing = false
                    }
                })
                
            } else if indexPath.section == 1 {
                presentConfirmAlert("Delete?", alertMessage: "Are you sure you want to delete this exercise? This action cannot be undone.", confirmTitle: "Delete", completion: { (confirm) -> Void in
                    if confirm {
                        // Delete the exercise
                        let idToDelete = self.exercises[indexPath.row].identifier
                        // Remove from core data
                        self.dataMgr.deleteItemByID(idToDelete, entityName: "Exercise", completion: { (success) -> Void in
                            if success {
                                // Remove from local array
                                self.exercises.removeAtIndex(indexPath.row)
                                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        if indexPath.section == 0 {
            // Display workout
            self.performSegueWithIdentifier("displayWorkoutFromSaved", sender: self)
        } else if indexPath.section == 1 {
            // Display an exercise
            self.performSegueWithIdentifier("displayExerciseFromSaved", sender: self)
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
        if segue.identifier == "displayExerciseFromSaved" && selectedIndex != -1 {
            let destinationVC = segue.destinationViewController as! DisplayExerciseTableViewController
            destinationVC.exerciseIdentifier = exercises[selectedIndex].identifier
            destinationVC.exerciseTitle = exercises[selectedIndex].title
            destinationVC.hideRateFeatures = true
        } else if segue.identifier == "displayWorkoutFromSaved" && selectedIndex != -1 {
            let destinationVC = segue.destinationViewController as! DisplayWorkoutTableViewController
            destinationVC.workoutIdentifier = workouts[selectedIndex].identifier
            destinationVC.displayingFromSaved = true
        }
        // Reset selected index
        selectedIndex = -1
    }
    

}
