//
//  CreateNewWorkoutTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/2/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData

class CreateNewWorkoutTableViewController: UITableViewController {
    
    var exercises = [Entry]()
    let defaults = NSUserDefaults.standardUserDefaults()
    let dataMgr = DataManager()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Get previously made entries
        exercises = dataMgr.retrieveEntries("workoutExercises")
        let newExercise = dataMgr.retrieveEntries("addedExercise")
        
        if newExercise.count > 0 {
            // exercise added to workout
            for newEx in newExercise {
                exercises.append(newEx)
            }
            defaults.removeObjectForKey("addedExercise")
        }
        
        
        let addedSavedExercises = dataMgr.retrieveEntries("exercisesToAdd")
        if addedSavedExercises.count > 0 {
            for savedExercise in addedSavedExercises {
                exercises.append(savedExercise)
            }
            defaults.removeObjectForKey("exercisesToAdd")
        }
        
        tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        // Store the current exercises in NSUserDefaults using the DataManager class
        dataMgr.storeEntries(exercises, key: "workoutExercises")
        
    }
    
    func getMyXercises(id : String) {
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext
        
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    exercises.append(Entry(exerciseTitle: result.valueForKey("name")! as! String, exerciseIdentifer: result.valueForKey("identifier")! as! String))
                }
            }
        } catch {
            print("There was an error fetching exercises")
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addExerciseButtonPressed(sender: AnyObject) {
        
        // Present action sheet to determine how to add exercise
        let actionSheet = UIAlertController(title: nil, message: "Would you like to create a new exercise or add one from My Xercises?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Create New", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.performSegueWithIdentifier("newExerciseFromWorkout", sender: self)
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
            
        } /*else if segue.identifier == "addFromSaved" {
            
        }*/
    }
    
    @IBAction func saveWorkoutButtonPressed(sender: AnyObject) {
        
        // Confirm that there is at least 1 exercise in the workout
        if exercises.count > 0 {
            // Present action sheet to determine if the workout is public or not and save appropriately
            
            
            // Remove exercises from defaults on success
            defaults.removeObjectForKey("workoutExercises")
            
            // Show success alert
            presentAlert("Success", alertMessage: "You workout has been successfully saved!")
        } else {
            // Show error alert
            presentAlert("Error", alertMessage: "There are no exercises in this workout. Please add at least one exercise before saving.")
        }
    }
    
    func presentAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if exercises.count > 0 {
            return exercises.count
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        
        if exercises.count > 0 {
            cell.textLabel?.text = exercises[indexPath.row].title
        } else {
            cell.textLabel?.text = "No exercises in this workout!"
        }
    
        cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)

        return cell
    }
    

    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}
