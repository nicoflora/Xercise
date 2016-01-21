//
//  DisplayWorkoutTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/8/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class DisplayWorkoutTableViewController: UITableViewController {
    
    let dataMgr = DataManager()
    let constants = XerciseConstants()
    var titles = [String]()
    var workoutIdentifier = ""
    var workoutToDisplay = Workout(name: "", muscleGroup: "", identifier: "", exerciseIds: [""], exerciseNames: nil, publicWorkout: false, workoutCode: nil)
    var exercises = [Entry]()
    var exerciseNames = [String]()
    var selectedIndex = -1
    var displayingFromSaved = false
    var activityIndicator = UIActivityIndicatorView()
    @IBOutlet var shareWithGroupButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        exercises.removeAll()
        self.clearsSelectionOnViewWillAppear = true
        
        if workoutIdentifier != "" {
            // There is an identifier for the workout - displaying a saved workout
            let workout = dataMgr.getWorkoutByID(workoutIdentifier)
            if let fetchedWorkout = workout {
                // Non-nil workout retrieved, use this to populate the data on-screen
                workoutToDisplay = fetchedWorkout
                let exerciseIds = workoutToDisplay.exerciseIDs
                // Get the name and ID of each exercise and add it to the array of exercises
                for exID in exerciseIds {
                    // Fetch the exercise from Core Data, make sure it has not been deleted
                    if let exercise = dataMgr.getEntryByID(exID, entityName: "Exercise") {
                        exercises.append(exercise)
                        exerciseNames.append(exercise.title)
                    }
                }
                // If the workout is public, check if the workout code is stored already
                if workoutToDisplay.publicWorkout {
                    if let code = workoutToDisplay.workoutCode {
                        // Code exists - display it
                        shareWithGroupButton.setTitle("Group Code: \(code)", forState: UIControlState.Normal)
                        self.shareWithGroupButton.enabled = false
                    } else {
                        // Workout was made public, but no code is stored - query for it
                        self.getWorkoutCode({ (success) -> Void in
                            if !success {
                                self.presentAlert("Error", message: "There was an error getting your group code, please try again.")
                                self.shareWithGroupButton.setTitle("Share with Group", forState: UIControlState.Normal)
                                self.shareWithGroupButton.enabled = true
                            }
                        })
                    }
                } else {
                    // Exercise is private - no code to display
                    shareWithGroupButton.setTitle("Share with Group", forState: UIControlState.Normal)
                }
            }
        } else {
            if let exerciseNames = workoutToDisplay.exerciseNames {
                // Displaying a generated workout
                for (index,id) in workoutToDisplay.exerciseIDs.enumerate() {
                    exercises.append(Entry(exerciseTitle: exerciseNames[index], exerciseIdentifer: id))
                }
            }
        }
        titles = constants.newWorkoutTitles
    }
    
    func getWorkoutCode(completion : (success : Bool) -> Void) {
        let workoutCode = dataMgr.queryParseForWorkoutCode(workoutToDisplay.identifier) { (success) -> Void in
            if success {
                // Get group code from Core Data
                let code = self.dataMgr.queryForWorkoutCode(self.workoutToDisplay.identifier)
                if code != "" {
                    self.shareWithGroupButton.setTitle("Group Code: \(code)", forState: UIControlState.Normal)
                    self.shareWithGroupButton.enabled = false
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func shareWithGroupButtonPressed(sender: AnyObject) {
        // Workout was previously private - prompt user then make workout public
        var error = false
        let alert = UIAlertController(title: "Share with Group?", message: "Sharing with a group will generate a code other users can enter to access your workout!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Upload to Parse
            self.displayActivityIndicator()
            //let exercises = self.dataMgr.archiveArray(self.workoutToDisplay.exerciseIDs)
            self.dataMgr.saveWorkoutToParse(self.workoutToDisplay.name, workoutMuscleGroup: self.workoutToDisplay.muscleGroup, id: self.workoutToDisplay.identifier, exerciseIDs: self.workoutToDisplay.exerciseIDs, exerciseNames: self.exerciseNames, completion: { (success) -> Void in
                self.removeActivityIndicator()
                if success {
                    // Uploaded to Parse, now check exercise availability
                    self.displayActivityIndicator()
                    self.dataMgr.checkParseExerciseAvailablity(self.workoutToDisplay.exerciseIDs, completion: { (success) -> Void in
                        self.removeActivityIndicator()
                        if success {
                            // Exercise availability is complete, now get ObjectID
                            self.getWorkoutCode({ (success) -> Void in
                                if success {
                                    self.presentAlert("Success", message: "Your workout has been uploaded to the community and can now be accessed by others by using the group code below.")
                                } else {
                                    error = true
                                }
                            })
                        } else {
                            error = true
                        }
                    })
                } else {
                   error = true
                }
                if error {
                    self.presentAlert("Error", message: "There was an error creating your group code, please try again.")
                    self.shareWithGroupButton.setTitle("Share with Group", forState: UIControlState.Normal)
                    self.shareWithGroupButton.enabled = true
                }
            })
        }))
        self.presentViewController(alert, animated: true, completion: nil)
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
    
    func presentAlert(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1 : return 1
        case 2:
            if exercises.count == 0 {
                return 1
            } else {
                return exercises.count
            }
        default: return 1
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = workoutToDisplay.name
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
        case 1:
            cell.textLabel?.text = "Muscle Group: \(workoutToDisplay.muscleGroup)"
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 15)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
        case 2:
            if exercises.count == 0 {
                cell.textLabel?.text = "There are no exercises in this workout!"
                cell.selectionStyle = UITableViewCellSelectionStyle.None
            } else {
                cell.textLabel?.text = exercises[indexPath.row].title
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 18)
        default:
            return cell
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            if exercises.count > indexPath.row {
                selectedIndex = indexPath.row
                self.performSegueWithIdentifier("displayExerciseFromWorkout", sender: self)
            }
        }
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayExerciseFromWorkout" && selectedIndex != -1 {
            let destinationVC = segue.destinationViewController as! DisplayExerciseTableViewController
            destinationVC.exerciseIdentifier = exercises[selectedIndex].identifier
            destinationVC.exerciseTitle = exercises[selectedIndex].title
            if displayingFromSaved {
                destinationVC.hideRateFeatures = true
            }
        }
        // Reset selected index value
        selectedIndex = -1
    }
    

}
