//
//  DisplayExerciseTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/7/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Parse
import Social
import MessageUI

class DisplayExerciseTableViewController: UITableViewController, MFMessageComposeViewControllerDelegate {

    var exerciseIdentifier = ""
    var muscleGroup = ""
    var hideRateFeatures = false
    let dataMgr = DataManager.sharedInstance
    let constants = XerciseConstants.sharedInstance
    var titles = [String]()
    var exerciseToDisplay = Exercise(name: "", muscleGroup: [String](), identifier: "", description: "", image: UIImage())
    var displayingGeneratedExercise = false
    var displayingExerciseInWorkout = false
    var downloadedExercises = [Exercise]()
    var nextExercises = [String]()
    var previousExercises = [String]()
    @IBOutlet var nextButton: UIBarButtonItem!
    var activityIndicator = UIActivityIndicatorView()
    var coverView = UIView()
    var setsAndReps = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titles = constants.displayExerciseTitles
        
        // Setup cover view
        coverView = UIView(frame: self.view.bounds)
        coverView.backgroundColor = UIColor.grayColor()
        coverView.alpha = 0.3
        
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
        
        // If there are no next exercises, remove next button
        if displayingExerciseInWorkout {
            if nextExercises.count == 0 {
                removeNextButton()
            }
        } else if !displayingGeneratedExercise {
            removeNextButton()
        }
        parseOutSetsAndReps()
    }
    
    override func viewDidDisappear(animated: Bool) {
        // Reset variable to hide rate features
        hideRateFeatures = false
    }
    
    func parseOutSetsAndReps() {
        var fullDesc = exerciseToDisplay.description
        
        // Get range of the start of the suggested sets and reps to remove from description later
        guard let heavyRange = fullDesc.rangeOfString("Suggested heavy lift (sets X reps): ", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) else {return}
        
        // Parse out heavy reps and sets
        let descSplitByHeavy = fullDesc.componentsSeparatedByString("Suggested heavy lift (sets X reps): ")
        guard let setsAndRepsString = descSplitByHeavy.last else {return}
        let heavyRepsSetsArray = setsAndRepsString.componentsSeparatedByString("Suggested endurance lift (sets X reps): ")
        guard var heavyReps = heavyRepsSetsArray.first else {return}
        heavyReps = heavyReps.stringByReplacingOccurrencesOfString(".", withString: "")
        
        // Parse out endurance reps and sets
        let descSplitByEndurance = setsAndRepsString.componentsSeparatedByString("Suggested endurance lift (sets X reps): ")
        guard var enduranceReps = descSplitByEndurance.last else {return}
        enduranceReps =  enduranceReps.stringByReplacingOccurrencesOfString(".", withString: "")
        
        setsAndReps = "Suggested sets X reps:\nHeavy lift: \(heavyReps)Endurance lift: \(enduranceReps)"
        
        // Fix description
        fullDesc = fullDesc.substringToIndex(heavyRange.startIndex)
        exerciseToDisplay.description = fullDesc
    }
    
    func imageResize(imageObj:UIImage, sizeChange:CGSize)-> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - "Next" navigation to change the currently displayed exercise
    
    @IBAction func nextButtonPressed(sender: AnyObject) {
        if displayingExerciseInWorkout {
            if nextExercises.count > 0 {
                let next = nextExercises.first
                if let nextExercise = next {
                    checkForExercise(nextExercise)
                    nextExercises.removeFirst()
                    if nextExercises.count == 0 {
                        // Remove Next button
                        removeNextButton()
                    }
                }
            }
        } else if displayingGeneratedExercise {
            // Displaying from a generated exercise, generate a new exercise with the same muscle group
            // Pass the previous exercise to prevent receiving duplicate exercises
            previousExercises.append(exerciseToDisplay.identifier)
            generateNewExercise(previousExercises)
        }
    }
    
    @IBAction func shareExerciseButtonPressed(sender: AnyObject) {
        shareAction()
    }
    
    
    func generateNewExercise(previousIdentifiers : [String]) {
        displayActivityIndicator()
        guard muscleGroup != "" else {return}
        dataMgr.generateExercise(muscleGroup, previousIdentifiers: previousIdentifiers, completion: { (exercise, resetPreviousIdentifiers) -> Void in
            if let exercise = exercise {
                self.exerciseToDisplay = exercise
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.changeExercise()
                })
                if resetPreviousIdentifiers {
                    self.previousExercises.removeAll()
                }
            } else {
                // Present alert
                self.removeActivityIndicator()
                self.presentAlert("Error", message: "There was an error loading your exercise. Please try again.")
            }
        })
    }
    
    func checkForExercise(id : String) {
        displayActivityIndicator()
        // Check if the exercise has already been downloaded and cached
        let cachedExercise = checkIfExerciseisCached(id)
        if let cachedExercise = cachedExercise {
            exerciseToDisplay = cachedExercise
            changeExercise()
        } else {
            // Exercise has not been downloaded yet - try to fetch workout from device
            let exercise = dataMgr.getExerciseByID(id)
            if let exercise = exercise {
                // In core data, present this exercise
                exerciseToDisplay = exercise
                // Cache exercise
                downloadedExercises.append(exercise)
                changeExercise()
            } else {
                // Fetch from Parse
                dataMgr.queryForExerciseFromParse(id, completion: { (exercise) -> Void in
                    if let exercise = exercise {
                        // Successfully retrieved an exercise
                        self.exerciseToDisplay = exercise
                        // Cache exercise
                        self.downloadedExercises.append(exercise)
                        self.changeExercise()
                    } else {
                        //print("Error fetching exercise from Parse")
                        self.presentAlert("Error", message: "There was an error retrieving this exercise, please make sure you are connected to the internet and try again.")
                    }
                    if self.activityIndicator.isAnimating() {
                        self.removeActivityIndicator()
                    }
                })
            }
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
    
    func changeExercise() {
        hideRateFeatures = false
        parseOutSetsAndReps()
        removeActivityIndicator()
        tableView.reloadData()
    }

    // MARK: - Share Action and rating
    
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
                        //self.presentAlert("Already Saved", message: "This exercise has already been saved in your 'My Xercises' page.")
                        self.showPopup("This exercise has already been saved in your 'My Xercises' page.")
                    } else {
                        // Exercise has not been saved to device, save it
                        // Convert image
                        if let img = UIImageJPEGRepresentation(self.exerciseToDisplay.image, 0.5) {
                            // Save exercise to device
                            self.dataMgr.saveExerciseToDevice(self.exerciseToDisplay.name, id: self.exerciseToDisplay.identifier, muscleGroup: self.exerciseToDisplay.muscleGroup, image: img, exerciseDescription: self.exerciseToDisplay.description, completion: { (success) -> Void in
                                if success {
                                    //self.presentAlert("Success", message: "The exercise has been saved to 'My Xercises'!")
                                    self.showPopup("The exercise has been saved to 'My Xercises'!")
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
            // Share to Facebook
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
                let facebookShare = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                facebookShare.setInitialText("Check out \(self.exerciseToDisplay.name) on the Xercise Fitness iOS App!\n\nDescription: \(self.exerciseToDisplay.description)")
                facebookShare.addImage(self.exerciseToDisplay.image)
                self.presentViewController(facebookShare, animated: true, completion: nil)
            } else {
                self.presentAlert("No Facebook Accounts", message: "Please login to a Facebook account in Settings to enable sharing to Facebook.")
            }
        }))
        shareActionSheet.addAction(UIAlertAction(title: "Share to Twitter", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            // Share to Twitter
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
                let twitterShare = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                twitterShare.setInitialText("Check out \(self.exerciseToDisplay.name) on the Xercise Fitness iOS App!")
                twitterShare.addImage(self.exerciseToDisplay.image)
                self.presentViewController(twitterShare, animated: true, completion: nil)
            } else {
                self.presentAlert("No Twitter Accounts", message: "Please login to a Twitter account in Settings to enable sharing to Twitter.")
            }
        }))
        if MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments() {
            shareActionSheet.addAction(UIAlertAction(title: "Share with Message", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                let messageVC = MFMessageComposeViewController()
                messageVC.messageComposeDelegate = self
                messageVC.navigationBar.tintColor = UIColor.whiteColor()
                messageVC.body = "Check out \(self.exerciseToDisplay.name) on the Xercise Fitness iOS App!\n\nDescription: \(self.exerciseToDisplay.description)"
                guard let imageData = UIImagePNGRepresentation(self.exerciseToDisplay.image) else {return}
                messageVC.addAttachmentData(imageData, typeIdentifier: "kUTTypePNG", filename: "xerciseImage.png")
                self.presentViewController(messageVC, animated: true, completion: nil)
            }))
        }
        shareActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(shareActionSheet, animated: true, completion: nil)
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func thumbsDownRate() {
        // Call to Parse Cloud Code to rate an exercise with a thumbs down
        let rateDictionary = ["type" : "Exercise", "id" : exerciseToDisplay.identifier, "rating" : "thumbs_Down_Rate"]
        PFCloud.callFunctionInBackground("rate", withParameters: rateDictionary) { (object, error) -> Void in
            self.rateCompleted()
            /*if error == nil {
                self.rateCompleted()
            } else {
                self.presentAlert("Error Rating", message: "There was an issue saving your rating, please try again.")
                print("Error: \(error!.localizedDescription)")
            }*/
        }
    }
    
    func thumbsUpRate() {
        // Call to Parse Cloud Code to rate an exercise with a thumbs up
        let rateDictionary = ["type" : "Exercise", "id" : exerciseToDisplay.identifier, "rating" : "thumbs_Up_Rate"]
        PFCloud.callFunctionInBackground("rate", withParameters: rateDictionary) { (object, error) -> Void in
            self.rateCompleted()
            /*if error == nil {
                self.rateCompleted()
            } else {
                self.presentAlert("Error Rating", message: "There was an issue saving your rating, please try again.")
                print("Error: \(error!.localizedDescription)")
            }*/
        }
    }
    
    func rateCompleted() {
        // Make UI changes to the thumbs up and thumbs down rate buttons
        hideRateFeatures = true
        tableView.reloadData()
    }
    
    
    // MARK: - Utility functions
    func showPopup(message : String) {
        let popup = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        self.presentViewController(popup, animated: true, completion: nil)
        self.performSelector(#selector(DisplayExerciseTableViewController.hidePopup), withObject: nil, afterDelay: 1.0)
    }
    
    func hidePopup() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func removeNextButton() {
        let rightButton = self.navigationItem.rightBarButtonItem
        if rightButton != nil {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    func displayActivityIndicator() {
        self.view.addSubview(coverView)
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.center = self.tableView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.alpha = 1.0
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.backgroundColor = UIColor.grayColor()
        activityIndicator.layer.cornerRadius = activityIndicator.bounds.width / 6
        self.view.addSubview(activityIndicator)
        self.view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func removeActivityIndicator() {
        coverView.removeFromSuperview()
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }


    func presentAlert(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func displayErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "There was an error loading your exercise. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if hideRateFeatures {
            return 5
        } else {
            return 6
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 2:
            return 230
        case 3:
            return 66
        case 4:
            return 170
        case 5:
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
            cell.textLabel?.numberOfLines = 2
            return cell
        case 1:
            let cell = UITableViewCell()
            var muscleGroupsString = ""
            for group in exerciseToDisplay.muscleGroup {
                if let lastGroup = exerciseToDisplay.muscleGroup.last {
                    if group == lastGroup {
                        muscleGroupsString += "\(group)"
                    } else {
                        muscleGroupsString += "\(group), "
                    }
                }
            }
            cell.textLabel?.text = "Muscle Group: \(muscleGroupsString)"
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 15)
            cell.textLabel?.numberOfLines = 2
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("displayExerciseImage", forIndexPath: indexPath) as! DisplayExerciseImageTableViewCell
            cell.exerciseImage.image = imageResize(exerciseToDisplay.image, sizeChange: cell.exerciseImage.frame.size)
            return cell
        case 3:
            let cell = UITableViewCell()
            cell.textLabel?.numberOfLines = 3
            if setsAndReps != "" {
                cell.textLabel?.text = setsAndReps
            } else {
                cell.textLabel?.text = "Suggested sets X reps:\nHeavy lift: 6 X 6\nEndurance lift: 3 X 12"
            }
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 15)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 4:
            let cell = tableView.dequeueReusableCellWithIdentifier("displayExerciseDescription", forIndexPath: indexPath) as! DisplayExerciseDescriptionTableViewCell
            cell.exerciseDescription.text = exerciseToDisplay.description
            cell.exerciseDescription.textAlignment = NSTextAlignment.Center
            cell.exerciseDescription.font = UIFont(name: "Marker Felt", size: 16)
            return cell
        case 5:
            if !hideRateFeatures {
                let cell = tableView.dequeueReusableCellWithIdentifier("displayExerciseShare", forIndexPath: indexPath) as! DisplayExerciseShareTableViewCell
                //cell.shareButton.addTarget(self, action: "shareAction", forControlEvents: UIControlEvents.TouchUpInside)
                
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
                    cell.thumbsDownRate.addTarget(self, action: #selector(DisplayExerciseTableViewController.thumbsDownRate), forControlEvents: UIControlEvents.TouchUpInside)
                    cell.thumbsUpRate.addTarget(self, action: #selector(DisplayExerciseTableViewController.thumbsUpRate), forControlEvents: UIControlEvents.TouchUpInside)
                }
                return cell
            } else {
                let cell = UITableViewCell()
                return cell
            }
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
}
