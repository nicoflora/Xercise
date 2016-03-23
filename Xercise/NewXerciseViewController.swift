//
//  ViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 10/27/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Parse

class NewXerciseViewController: UIViewController, IGLDropDownMenuDelegate, UITabBarControllerDelegate {
    
    @IBOutlet var animationImage: UIImageView!
    @IBOutlet var getWorkoutButton: UIButton!
    @IBOutlet var getExerciseButton: UIButton!
    
    let dataMgr = DataManager.sharedInstance
    var imageCounter = 1
    var isAnimatingImage = false
    var timer = NSTimer()
    var muscleGroups = [MuscleGroup]()
    var previousWorkoutIdentifiers = [String]()
    var selectedMuscleGroup = ""
    var exercise = Exercise(name: "", muscleGroup: [String](), identifier: "", description: "", image: UIImage())
    var workout = Workout(name: "", muscleGroup: [String](), identifier: "", exerciseIds: [""], exerciseNames: nil, publicWorkout: false, workoutCode: nil)
    var disclaimerAccepted = false
    let coverView = UIView(frame: UIScreen.mainScreen().bounds)
    var mainGroupDropDownMenu = IGLDropDownMenu()
    var subGroupDropDownMenu = IGLDropDownMenu()
    var selectedMainMuscleGroupIndex = -1
    var selectedSubMuscleGroupIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let constants = XerciseConstants.sharedInstance
        muscleGroups = constants.muscleGroupsArray
        
        getWorkoutButton.layer.cornerRadius = 10
        getExerciseButton.layer.cornerRadius = 10
        
        // Style Get Exercise and Get Workout buttons
        getExerciseButton.backgroundColor = UIColor.groupTableViewBackgroundColor()
        getExerciseButton.layer.borderWidth = 3.0
        getExerciseButton.layer.borderColor = UIColor(hexString: "#2c4b85").CGColor
        getExerciseButton.setTitleColor(UIColor(hexString: "#2c4b85"), forState: UIControlState.Normal)
        getExerciseButton.layer.shadowColor = UIColor.grayColor().CGColor
        getExerciseButton.layer.shadowOffset = CGSizeMake(0, 0)
        getExerciseButton.layer.shadowOpacity = 0.5
        
        getWorkoutButton.backgroundColor = UIColor.groupTableViewBackgroundColor()
        getWorkoutButton.layer.borderWidth = 3.0
        getWorkoutButton.layer.borderColor = UIColor(hexString: "#2c4b85").CGColor
        getWorkoutButton.setTitleColor(UIColor(hexString: "#2c4b85"), forState: UIControlState.Normal)
        getWorkoutButton.layer.shadowColor = UIColor.grayColor().CGColor
        getWorkoutButton.layer.shadowOffset = CGSizeMake(0, 0)
        getWorkoutButton.layer.shadowOpacity = 0.5
        
        checkForDisclaimerAcceptance()
    }
    
    override func viewWillAppear(animated: Bool) {
        // Check user login
        if PFUser.currentUser() == nil {
            //If not logged in, display login view controller
            presentLoginVC()
        }
        
        tabBarController?.delegate = self
        setupDropDownMenu()

    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.delegate = nil
        
        isAnimatingImage = false
        timer.invalidate()
        
        if mainGroupDropDownMenu.expanding {
            mainGroupDropDownMenu.toggleView()
        }
        if subGroupDropDownMenu.expanding {
            subGroupDropDownMenu.toggleView()
        }
    }
    
    
    // MARK: - Drop Down Functions
    
    func setupDropDownMenu() {
        // Setup Main Group Dropdown
        var dropdownItems = [IGLDropDownItem]()
        for group in muscleGroups {
            dropdownItems.append(createDropDownItem(group.mainGroup, dropDownHeader: false))
        }
        if selectedMainMuscleGroupIndex == -1 {
            // Main Muscle Group NOT Selected
            mainGroupDropDownMenu = createDropDownMenu(CGRectZero, menuButtonTitle: "Select a Main Muscle Group...", dropDownItems: dropdownItems)
            subGroupDropDownMenu = createDropDownMenu(CGRectZero, menuButtonTitle: "All Sub Muscle Groups", dropDownItems: [createDropDownItem("All Sub Muscle Groups", dropDownHeader: false)])
        } else if muscleGroups.count > selectedMainMuscleGroupIndex {
            // Main Muscle Group Selected
            mainGroupDropDownMenu = createDropDownMenu(CGRectZero, menuButtonTitle: muscleGroups[selectedMainMuscleGroupIndex].mainGroup, dropDownItems: dropdownItems)
            
            // Setup Sub Group Dropdown
            if muscleGroups[selectedMainMuscleGroupIndex].subGroups.count > selectedSubMuscleGroupIndex {
                if selectedSubMuscleGroupIndex == -1 {
                    // Sub group NOT selected
                    subGroupDropDownMenu = createDropDownMenu(CGRectZero, menuButtonTitle: "All Sub Muscle Groups", dropDownItems: getSubMuscleGroupsForMainGroupAtIndex(selectedMainMuscleGroupIndex))
                } else {
                    // Sub group selected
                    subGroupDropDownMenu = createDropDownMenu(CGRectZero, menuButtonTitle: muscleGroups[selectedMainMuscleGroupIndex].subGroups[selectedSubMuscleGroupIndex], dropDownItems: getSubMuscleGroupsForMainGroupAtIndex(selectedMainMuscleGroupIndex))
                }
            }
        }
        var firstDropDownYValue : CGFloat = 64
        if let navBarHeight = self.navigationController?.navigationBar.frame.maxY {
            firstDropDownYValue = navBarHeight
        }
        mainGroupDropDownMenu.frame = CGRectMake((UIScreen.mainScreen().bounds.width - 275) / 2, firstDropDownYValue + 15, 275, 40)
        self.view.addSubview(mainGroupDropDownMenu)
        mainGroupDropDownMenu.reloadView()

        subGroupDropDownMenu.frame = CGRectMake((UIScreen.mainScreen().bounds.width - 250) / 2, mainGroupDropDownMenu.frame.maxY + 15, 250, 40)
        self.view.addSubview(subGroupDropDownMenu)
        subGroupDropDownMenu.reloadView()
    }
    
    func createDropDownItem(menuText : String, dropDownHeader : Bool) -> IGLDropDownItem {
        let dropDownItem = IGLDropDownItem()
        dropDownItem.text = menuText
        dropDownItem.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        if dropDownHeader {
            // Apply special styling for header
            /*
            // Styling with blue background - white text
            dropDownItem.backgroundColor = UIColor(hexString: "#2c4b85")
            dropDownItem.textLabel.textColor = UIColor.whiteColor()
            */
            
            // Styling with gray background, blue text and blue border
            dropDownItem.backgroundColor = UIColor.groupTableViewBackgroundColor()
            dropDownItem.layer.borderWidth = 3.0
            dropDownItem.layer.borderColor = UIColor(hexString: "#2c4b85").CGColor
            dropDownItem.layer.cornerRadius = 10
            dropDownItem.textLabel.textColor = UIColor(hexString: "#2c4b85")
            
        }
        return dropDownItem
    }
    
    func createDropDownMenu(frame : CGRect, menuButtonTitle : String, dropDownItems : [IGLDropDownItem]) -> IGLDropDownMenu {
        let dropDownMenu = IGLDropDownMenu()
        dropDownMenu.frame = frame
        dropDownMenu.menuButton = createDropDownItem(menuButtonTitle, dropDownHeader: true)
        dropDownMenu.menuText = menuButtonTitle
        dropDownMenu.dropDownItems = dropDownItems
        dropDownMenu.type = IGLDropDownMenuType.FlipVertical
        dropDownMenu.itemAnimationDelay = 0
        dropDownMenu.layer.shadowColor = UIColor.grayColor().CGColor
        dropDownMenu.layer.shadowOffset = CGSizeMake(0, 0)
        dropDownMenu.layer.shadowOpacity = 0.5
        dropDownMenu.delegate = self
        return dropDownMenu
    }
    
    func dropDownMenu(dropDownMenu: IGLDropDownMenu!, selectedItemAtIndex index: Int) {
        if dropDownMenu == mainGroupDropDownMenu  {
            // Main Group selection made - set class-level variables
            selectedMainMuscleGroupIndex = index
            selectedSubMuscleGroupIndex = -1
            self.selectedMuscleGroup = self.muscleGroups[index].mainGroup

            // Update sub groups
            subGroupDropDownMenu.enabled = false
            subGroupDropDownMenu.menuText = "All Sub Muscle Groups"
            subGroupDropDownMenu.dropDownItems = getSubMuscleGroupsForMainGroupAtIndex(index)
            subGroupDropDownMenu.reloadView()
            subGroupDropDownMenu.enabled = true
            
        } else if dropDownMenu == subGroupDropDownMenu {
            // Sub group selection made
            if index > 0 {
                if selectedMainMuscleGroupIndex != -1 && muscleGroups.count > selectedMainMuscleGroupIndex {
                    if self.muscleGroups[selectedMainMuscleGroupIndex].subGroups.count > index {
                        self.selectedMuscleGroup = self.muscleGroups[selectedMainMuscleGroupIndex].subGroups[index]
                        selectedSubMuscleGroupIndex = index
                    }
                }
            } else {
                // All option chosen - reset to main muscle group
                if selectedMainMuscleGroupIndex != -1 && self.muscleGroups.count > selectedMainMuscleGroupIndex {
                    selectedSubMuscleGroupIndex = -1
                    self.selectedMuscleGroup = self.muscleGroups[selectedMainMuscleGroupIndex].mainGroup
                }
            }
        }
    }
    
    func dropDownMenu(dropDownMenu: IGLDropDownMenu!, expandingChanged isExpending: Bool) {
        if isExpending {
            // Check to collapse & hide other dropdowns
            if dropDownMenu == mainGroupDropDownMenu {
                self.view.bringSubviewToFront(dropDownMenu)
                if subGroupDropDownMenu.expanding {
                    subGroupDropDownMenu.toggleView()
                }
            } else if dropDownMenu == subGroupDropDownMenu {
                if mainGroupDropDownMenu.expanding {
                    mainGroupDropDownMenu.toggleView()
                }
            }
        }
    }
    
    func getSubMuscleGroupsForMainGroupAtIndex(index : Int) -> [IGLDropDownItem] {
        var subMuscleGroupDropDownItems = [IGLDropDownItem]()
        for (subIndex, _) in muscleGroups[index].subGroups.enumerate() {
            let subDropDownItem = IGLDropDownItem()
            subDropDownItem.text = muscleGroups[index].subGroups[subIndex]
            subDropDownItem.backgroundColor = UIColor.groupTableViewBackgroundColor()
            subDropDownItem.textLabel.textColor = UIColor(hexString: "#0f3878")
            subDropDownItem.textLabel.font = UIFont(name: "Marker Felt", size: 18)
            subMuscleGroupDropDownItems.append(subDropDownItem)
        }
        return subMuscleGroupDropDownItems
    }
    
    
    // MARK: - Disclaimer Function
    
    func checkForDisclaimerAcceptance() {
        let defaults = NSUserDefaults.standardUserDefaults()
        //defaults.setBool(false, forKey: "acceptedDisclaimer") // ** Testing only
        if !defaults.boolForKey("acceptedDisclaimer") {
            // Add cover view
            //let coverView = UIView(frame: UIScreen.mainScreen().bounds)
            coverView.backgroundColor = UIColor.darkGrayColor()
            coverView.alpha = 1
            
            let touchRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewXerciseViewController.disclaimerDeniedTouches(_:)))
            coverView.addGestureRecognizer(touchRecognizer)
            
            let label = UILabel(frame: CGRectMake(0,0,300,90))
            label.numberOfLines = 3
            label.textAlignment = NSTextAlignment.Center
            label.text = "You must accept the Disclaimer before using the App!"
            label.font = UIFont(name: "Marker Felt", size: 20)
            label.textColor = UIColor.whiteColor()
            label.center = coverView.center
            coverView.addSubview(label)
            guard let navigationController = navigationController else {return}
            
            if !navigationController.view.subviews.contains(coverView) {
            navigationController.view.addSubview(coverView)
            }
        
            // Show alert
            let alert = UIAlertController(title: "Disclaimer", message: "By using this application, you hereby accept the Privacy Policy of Xercise Fitness, and accept that you perform any exercise or workout obtained from the app at your own risk. Xercise Fitness recommends that you consult with a doctor prior to participating in any physical activity.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Don't Accept", style: UIAlertActionStyle.Default, handler: nil))
            alert.addAction(UIAlertAction(title: "Read Privacy Policy", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                guard let url = NSURL(string: "http://aristotleii.monmouth.edu/~s0874982/Xercise/mobile-privacy-policy.html") else {return}
                UIApplication.sharedApplication().openURL(url)
            }))
            alert.addAction(UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                defaults.setBool(true, forKey: "acceptedDisclaimer")
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.coverView.removeFromSuperview()
                })
                self.disclaimerAccepted = true
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            disclaimerAccepted = true
        }
        
    }
    
    func disclaimerDeniedTouches(gesture : UITapGestureRecognizer) {
        checkForDisclaimerAcceptance()
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if !disclaimerAccepted {
            return false
        }
        return true
    }
    
    
    // MARK: - IBAction Functions
    
    @IBAction func getExerciseButtonPressed(sender: AnyObject) {
        // Start animation
        updateImage(self)
        
        // Fetch an exercise from Cloud Code
        if selectedMuscleGroup != "" {
            // Begin ignoring interaction events
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            
            dataMgr.generateExercise(selectedMuscleGroup, previousIdentifiers: nil, completion: { (exercise, resetPreviousIdentifiers) -> Void in
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                if let exercise = exercise {
                    self.exercise = exercise
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.performSegueWithIdentifier("getExercise", sender: self)
                    })
                } else {
                    // Present alert
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.presentAlert("Error", alertMessage: "There was an error loading your exercise. Please try again.")
                        self.updateImage(self)
                    })
                }
            })
        } else {
            self.presentAlert("No Muscle Group", alertMessage: "There was no muscle group selected. Please choose one and try again.")
            self.updateImage(self)
        }
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL, completion : (image : UIImage?) -> Void) {
        //"Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else {
                    //print(error?.localizedDescription)
                    completion(image: nil)
                    return
                }
                //print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
                completion(image: UIImage(data: data)!)
            }
        }
    }
    
    @IBAction func getWorkoutButtonPressed(sender: AnyObject) {
        // Start animation
        updateImage(self)
        
        if selectedMuscleGroup != "" {
            // Begin ignoring interaction events
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            dataMgr.generateWorkout(selectedMuscleGroup, previousIdentifiers: self.previousWorkoutIdentifiers, completion: { (workout, resetPreviousIdentifiers) -> Void in
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                if let workout = workout {
                    self.workout = workout
                    self.previousWorkoutIdentifiers.append(workout.identifier)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.performSegueWithIdentifier("getWorkout", sender: self)
                    })
                } else {
                    // Present alert
                    self.presentAlert("Error", alertMessage: "There was an error loading your workout. Please try again.")
                    self.updateImage(self)
                }
                
                // Check if the previousWorkoutIdentifiers need to be reset
                if resetPreviousIdentifiers {
                    self.previousWorkoutIdentifiers.removeAll()
                }
            })
        } else {
            self.presentAlert("No Muscle Group", alertMessage: "There was no muscle group selected. Please choose one and try again.")
            self.updateImage(self)
        }

    }
    
    func updateImage(sender: AnyObject) {
        if isAnimatingImage == false {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: #selector(NewXerciseViewController.animateImage), userInfo: nil, repeats: true)
            isAnimatingImage = true
        } else {
            isAnimatingImage = false
            timer.invalidate()
        }
    }
    
    func animateImage() {
        if imageCounter == 9 {
            imageCounter = 1
        } else {
            imageCounter += 1
        }
        animationImage.image = UIImage(named: "animationFrame\(imageCounter)")
    }
    
    
    @IBAction func logout(sender: AnyObject) {
        let confirmLogout = UIAlertController(title: "Logout?", message: "Are you sure you want to logout?", preferredStyle: UIAlertControllerStyle.Alert)
        confirmLogout.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        confirmLogout.addAction(UIAlertAction(title: "Logout", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            PFUser.logOut()
            self.presentLoginVC()
        }))
        
        self.presentViewController(confirmLogout, animated: true, completion: nil)
    }
    
    
    func presentLoginVC() {
        guard let loginVC = self.storyboard?.instantiateInitialViewController() else {return}
        self.presentViewController(loginVC, animated: false, completion: nil)
    }
    
    func displayErrorAlert() {
        let alert = UIAlertController(title: "Error", message: "There was an error loading your exercise. Please try again.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "getExercise" {
            let destinationVC = segue.destinationViewController as! DisplayExerciseTableViewController
            destinationVC.displayingGeneratedExercise = true
            destinationVC.exerciseToDisplay = exercise
            destinationVC.muscleGroup = selectedMuscleGroup
        } else if segue.identifier == "getWorkout" {
            let destinationVC = segue.destinationViewController as! DisplayWorkoutTableViewController
            destinationVC.workoutToDisplay = workout
            
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}