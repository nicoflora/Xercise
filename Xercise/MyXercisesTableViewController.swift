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

    var workoutTitles = [String]()
    var exerciseTitles = [String]()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        //getMyXercises()
    }
    
    override func viewWillAppear(animated: Bool) {
        // Fetch data
        getMyXercises()
        tableView.reloadData()
    }
    
    
    func getMyXercises() {
        
        workoutTitles.removeAll()
        exerciseTitles.removeAll()
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext
        
        let requestWorkout = NSFetchRequest(entityName: "Workout")
        requestWorkout.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestWorkout)
            //print(results)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    //print(result.valueForKey("exercise_desc")!)
                    workoutTitles.append(result.valueForKey("name")! as! String)
                }
            }
        } catch {
            print("There was an error fetching workouts")
        }
        
        
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            //print(results)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    //print(result.valueForKey("exercise_desc")!)
                    exerciseTitles.append(result.valueForKey("name")! as! String)
                }
            }
        } catch {
            print("There was an error fetching exercises")
        }
        
        /*
        // ** Only use this line to delete bad data in development **
        requestExercise.predicate = NSPredicate(format: "name = %@", "")
        requestExercise.returnsObjectsAsFaults = false
        
        do {
        let results = try context.executeFetchRequest(requestExercise)
        
        if results.count > 0 {
        for result in results as! [NSManagedObject] {
        context.deleteObject(result)
        print("Deleted object")
        
        do {
        try context.save()
        } catch {
        print("There was an error saving the data")
        }
        }
        }
        }  catch {
        print("There was an error fetching the data")
        }*/
 
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
            if workoutTitles.count == 0 {
                return 1
            } else {
                return workoutTitles.count
            }
        } else if section == 1 {
            if exerciseTitles.count == 0 {
                return 1
            } else {
                return exerciseTitles.count
            }
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        let cell = UITableViewCell()

        if indexPath.section == 0 {
            if workoutTitles.count > 0 {
                cell.textLabel?.text = workoutTitles[indexPath.row]
            } else {
                cell.textLabel?.text = "No workouts saved!"
            }
        } else if indexPath.section == 1 {
            if exerciseTitles.count > 0 {
                cell.textLabel?.text = exerciseTitles[indexPath.row]
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
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
