//
//  DisplayWorkoutTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/8/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Social
import MessageUI

class DisplayWorkoutTableViewController: UITableViewController, XercisesUpdatedDelegate, MFMessageComposeViewControllerDelegate {
    
    let dataMgr = DataManager.sharedInstance
    let constants = XerciseConstants.sharedInstance
    var workoutIdentifier = ""
    var workoutToDisplay = Workout(name: "", muscleGroup: [String](), identifier: "", exerciseIds: [""], exerciseNames: nil, publicWorkout: false, workoutCode: nil)
    var exerciseToDisplay = Exercise(name: "", muscleGroup: [String](), identifier: "", description: "", image: UIImage())
    var downloadedExercises = [Exercise]()
    var exercises = [Entry]()
    var exerciseNames = [String]()
    var selectedIndex = -1
    var displayingFromSaved = false
    var displayingGeneratedWorkout = false
    var activityIndicator = UIActivityIndicatorView()
    @IBOutlet var shareWithGroupButton: UIButton!
    var copyPopup = UIAlertController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataMgr.updateXercisesDelegate = self

        fetchWorkout()
        
        self.clearsSelectionOnViewWillAppear = true
        
    }
    
    func updateXercises() {
        fetchWorkout()
        tableView.reloadData()
    }
    
    func fetchWorkout() {
        exercises.removeAll()

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
            }
        } else {
            if let exerciseNames = workoutToDisplay.exerciseNames {
                if exerciseNames.count > 0 {
                    // Displaying a generated workout
                    displayingGeneratedWorkout = true
                    for (index,id) in workoutToDisplay.exerciseIDs.enumerate() {
                        guard let mainMuscleGroup = workoutToDisplay.muscleGroup.first else {return}
                        exercises.append(Entry(exerciseTitle: exerciseNames[index], exerciseIdentifer: id, muscle_group: mainMuscleGroup))
                    }
                }
            }
        }
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func shareWithGroupButtonPressed(sender: AnyObject) {
        var commaSeparatedExercises = ""
        for exercise in self.exercises {
            if commaSeparatedExercises == "" {
                commaSeparatedExercises += "\(exercise.title)"
            } else {
                commaSeparatedExercises += ", \(exercise.title)"
            }
        }

        // Share button pressed
        let shareActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        if displayingGeneratedWorkout {
            shareActionSheet.addAction(UIAlertAction(title: "Save Workout", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                // Save to device
                // Check if the workout already exists
                self.dataMgr.queryForItemByID(self.workoutToDisplay.identifier, entityName: "Workout", completion: { (success) -> Void in
                    if success {
                        // Workout is already saved, alert user of this
                        //self.presentAlert("Already Saved", message: "This workout has already been saved in your 'My Xercises' page.")
                        self.showPopup("This workout has already been saved in your 'My Xercises' page.")
                    } else {
                        // Workout has not been saved to device, save it
                        self.dataMgr.saveWorkoutToDevice(false, workoutName: self.workoutToDisplay.name, workoutMuscleGroup: self.workoutToDisplay.muscleGroup, id: self.workoutToDisplay.identifier, exerciseIDs: self.workoutToDisplay.exerciseIDs, publicWorkout: true, completion: { (success) -> Void in
                            if success {
                                //self.presentAlert("Saved!", message: "The workout has been saved to 'My Xercises'!")
                                self.showPopup("The workout has been saved to 'My Xercises'!")
                            } else {
                                self.presentAlert("Error", message: "There was a problem saving this workout, please try again.")
                            }
                        })
                    }
                })
            }))
        }
        shareActionSheet.addAction(UIAlertAction(title: "Share to Facebook", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Share to Facebook
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
                let facebookShare = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                facebookShare.setInitialText("Check out this awesome workout I found on the Xercise Fitness iOS App! \n\nExercises: \(commaSeparatedExercises)")
                facebookShare.addImage(UIImage(named: "AppIcon"))
                self.presentViewController(facebookShare, animated: true, completion: nil)
            } else {
                self.presentAlert("No Facebook Accounts", message: "Please login to a Facebook account in Settings to enable sharing to Facebook.")
            }
        }))
        shareActionSheet.addAction(UIAlertAction(title: "Share to Twitter", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Share to Twitter
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
                let twitterShare = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                twitterShare.setInitialText("Check out this awesome workout I found on the Xercise Fitness iOS App! \n\nExercises: \(commaSeparatedExercises)")
                twitterShare.addImage(UIImage(named: "AppIcon"))
                self.presentViewController(twitterShare, animated: true, completion: nil)
            } else {
                self.presentAlert("No Twitter Accounts", message: "Please login to a Twitter account in Settings to enable sharing to Twitter.")
            }
        }))
        if MFMessageComposeViewController.canSendText() {
            shareActionSheet.addAction(UIAlertAction(title: "Share with Message", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                let messageVC = MFMessageComposeViewController()
                messageVC.messageComposeDelegate = self
                messageVC.navigationBar.tintColor = UIColor.whiteColor()
                messageVC.body = "Check out \(self.workoutToDisplay.name) on the Xercise Fitness iOS App!\n\nExercises in this workout: \(commaSeparatedExercises)"
                self.presentViewController(messageVC, animated: true, completion: nil)
            }))
        }
        if !self.displayingGeneratedWorkout && !self.workoutToDisplay.publicWorkout {
            shareActionSheet.addAction(UIAlertAction(title: "Share with Group", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                
                // prompt user then make workout public
                var error = false
                let alert = UIAlertController(title: "Share with Group?", message: "Sharing with a group will generate a code other users can enter to access your workout!", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    // Upload to Parse
                    self.displayActivityIndicator()
                    //let exercises = self.dataMgr.archiveArray(self.workoutToDisplay.exerciseIDs)
                    self.dataMgr.saveWorkoutToDB(self.workoutToDisplay.name, workoutMuscleGroup: self.workoutToDisplay.muscleGroup, id: self.workoutToDisplay.identifier, exerciseIDs: self.workoutToDisplay.exerciseIDs, exerciseNames: self.exerciseNames, completion: { (success, identifier) -> Void in
                        self.removeActivityIndicator()
                        if success {
                            // Uploaded to Parse, now check exercise availability
//                            self.displayActivityIndicator()
//                            self.dataMgr.checkParseExerciseAvailablity(self.workoutToDisplay.exerciseIDs, completion: { (success) -> Void in
//                                self.removeActivityIndicator()
//                                if success {
                                    // Exercise availability is complete, now get ObjectID
                                    if let identifier = identifier {
                                        self.workoutIdentifier = identifier
                                        self.fetchWorkout()
                                        self.tableView.reloadData()
                                        /*
                                        if let workout = self.dataMgr.getWorkoutByID(identifier) {
                                            self.workoutToDisplay = workout
                                            self.tableView.reloadData()
                                        }*/
                                    }
//                                } else {
//                                    error = true
//                                }
//                            })
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
            }))
        }
        shareActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(shareActionSheet, animated: true, completion: nil)
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
    
    func checkForExercise(id : String) {
        if displayingGeneratedWorkout {
            displayActivityIndicator()
            // Check if the exercise has already been downloaded and cached
            let cachedExercise = checkIfExerciseisCached(id)
            if let cachedExercise = cachedExercise {
                exerciseToDisplay = cachedExercise
                self.performSegueWithIdentifier("displayExerciseFromWorkout", sender: self)
                removeActivityIndicator()
            } else {
                // Exercise has not been downloaded yet - try to fetch workout from device
                let exercise = dataMgr.getExerciseByID(id)
                if let exercise = exercise {
                    // In core data, present this exercise
                    exerciseToDisplay = exercise
                    self.performSegueWithIdentifier("displayExerciseFromWorkout", sender: self)
                    removeActivityIndicator()
                    // Cache exercise
                    downloadedExercises.append(exercise)
                } else {
                    // Fetch from Firebase
                    dataMgr.getExerciseFromDB(withID: id, completion: { (exercise) in
                        if let exercise = exercise {
                            // Successfully retrieved an exercise
                            self.exerciseToDisplay = exercise
                            self.performSegueWithIdentifier("displayExerciseFromWorkout", sender: self)
                            // Cache exercise
                            self.downloadedExercises.append(exercise)
                        } else {
                            //print("Error fetching exercise from Parse")
                            self.presentAlert("Error", message: "There was an error retrieving this exercise, please make sure you are connected to the internet and try again.")
                        }
                        self.removeActivityIndicator()
                    })
                }
            }
        } else {
            self.performSegueWithIdentifier("displayExerciseFromWorkout", sender: self)
        }
    }
    
    func checkIfExerciseisCached(id : String) -> Exercise? {
        for exercise in downloadedExercises {
            if exercise.identifier == id {
                // The exercise has been downloaded - return it
                return exercise
            }
        }
        return nil
    }
    
    func presentAlert(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if workoutToDisplay.publicWorkout {
            switch section {
            case 0: return 1
            case 1: return 1
            case 2:
                if exercises.count == 0 {
                    return 1
                } else {
                    return exercises.count + 1
                }
            default: return 1
            }
        } else {
            switch section {
            case 0: return 1
            case 1: return 1
            case 2:
                if exercises.count == 0 {
                    return 1
                } else {
                    return exercises.count
                }
            default: return 1
            }
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
            switch indexPath.section {
            case 0:
                cell.textLabel?.text = workoutToDisplay.name
                cell.textLabel?.textAlignment = NSTextAlignment.Center
                cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
                cell.textLabel?.numberOfLines = 2
                cell.selectionStyle = UITableViewCellSelectionStyle.None
            case 1:
                var muscleGroupsString = ""
                for group in workoutToDisplay.muscleGroup {
                    if let lastGroup = workoutToDisplay.muscleGroup.last {
                        if group == lastGroup {
                            muscleGroupsString += "\(group)"
                        } else {
                            muscleGroupsString += "\(group), "
                        }
                    }
                }
                cell.textLabel?.text = "Muscle Groups: \(muscleGroupsString)"
                cell.textLabel?.textAlignment = NSTextAlignment.Center
                cell.textLabel?.font = UIFont(name: "Marker Felt", size: 15)
                cell.textLabel?.numberOfLines = 2
                cell.selectionStyle = UITableViewCellSelectionStyle.None
            case 2:
                if exercises.count == 0 {
                    cell.textLabel?.text = "There are no exercises in this workout!"
                    cell.selectionStyle = UITableViewCellSelectionStyle.None
                } else {
                    if exercises.count > indexPath.row {
                        cell.textLabel?.text = exercises[indexPath.row].title
                        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                    } else if workoutToDisplay.publicWorkout {
                        cell.textLabel?.text = "Group Code: \(workoutToDisplay.identifier)"
                        cell.textLabel?.textAlignment = NSTextAlignment.Center
                        cell.textLabel?.font = UIFont(name: "Marker Felt", size: 15)
                        cell.selectionStyle = UITableViewCellSelectionStyle.Gray
                        cell.accessoryType = UITableViewCellAccessoryType.DetailButton
                    }
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
                checkForExercise(exercises[selectedIndex].identifier)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            } else if workoutToDisplay.publicWorkout && exercises.count > 0 {
                copyText(workoutToDisplay.identifier)
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
    }
    
    
    // MARK: - Utility functions
    
    func copyText(text : String) {
        let pasteBoard = UIPasteboard.generalPasteboard()
        pasteBoard.string = text
        showPopup("The group code \(text) was copied!")
        
    }
    
    func showPopup(message : String) {
        let copyPopup = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        self.presentViewController(copyPopup, animated: true, completion: {
            dispatch_async(dispatch_get_main_queue(), { 
                self.performSelector(#selector(DisplayWorkoutTableViewController.hidePopup), withObject: nil, afterDelay: 1.0)
            })
        })
    }
    
    func hidePopup() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayExerciseFromWorkout" && selectedIndex != -1 {
            let destinationVC = segue.destinationViewController as! DisplayExerciseTableViewController
            // Get next exercise identifiers
            if exercises.count > selectedIndex + 1 {
                var nextExercises = [String]()
                var i = selectedIndex + 1
                while i < exercises.count {
                    nextExercises.append(exercises[i].identifier)
                    i += 1
                }
                /*
                // Depreciated in Swift 2.2
                for var i = selectedIndex + 1; i < exercises.count; i++ {
                    nextExercises.append(exercises[i].identifier)
                }*/
                destinationVC.nextExercises = nextExercises
            }
            destinationVC.displayingExerciseInWorkout = true
            // Handle differences in displaying from saved/generated workout
            if displayingFromSaved {
                destinationVC.hideRateFeatures = true
            }
            // Check if the exercise is being displayed from a generated workout
            if displayingGeneratedWorkout {
                if exerciseToDisplay.name != "" {
                    destinationVC.displayingGeneratedExercise = true
                    destinationVC.exerciseToDisplay = exerciseToDisplay
                    destinationVC.downloadedExercises = downloadedExercises
                } else {
                    // handle error
                }
            } else {
                destinationVC.exerciseIdentifier = exercises[selectedIndex].identifier
            }
        }
        // Reset selected index value
        selectedIndex = -1
    }
    

}
