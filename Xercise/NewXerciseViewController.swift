//
//  ViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 10/27/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Parse
import ParseUI
//import ParseFacebookUtilsV4

class NewXerciseViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    @IBOutlet var animationImage: UIImageView!
    @IBOutlet var selectMuscleGroupBtn: UIButton!
    
    var imageCounter = 1
    var isAnimatingImage = false
    var timer = NSTimer()
    var muscleGroups = [String]()
    var selectedMuscleGroup = ""
    var exercise = Exercise(name: "", muscleGroup: "", identifier: "", description: "", image: UIImage())
    var workout = Workout(name: "", muscleGroup: "", identifier: "", exerciseIds: [""], exerciseNames: nil, publicWorkout: false, workoutCode: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let constants = XerciseConstants()
        muscleGroups = constants.muscleGroups
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // Check user login
        if PFUser.currentUser() == nil {
            //If not logged in, display Parse login view controller
            presentLoginVC()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        isAnimatingImage = false
        timer.invalidate()
    }
    
    @IBAction func selectMuscleGroupBtnPressed(sender: AnyObject) {
        
        if muscleGroups.count == 5 {
            let actionSheet = UIAlertController(title: nil, message: "Select a muscle group:", preferredStyle: UIAlertControllerStyle.ActionSheet)
            actionSheet.addAction(UIAlertAction(title: muscleGroups[0], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectedMuscleGroup = self.muscleGroups[0]
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[0])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[1], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectedMuscleGroup = self.muscleGroups[1]
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[1])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[2], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectedMuscleGroup = self.muscleGroups[2]
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[2])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[3], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectedMuscleGroup = self.muscleGroups[3]
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[3])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[4], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectedMuscleGroup = self.muscleGroups[4]
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[4])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func getExerciseButtonPressed(sender: AnyObject) {
        // Start animation
        updateImage(self)
        
        // Fetch an exercise from Cloud Code
        if selectedMuscleGroup != "" {
            // Begin ignoring interaction events
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()

            // Call Parse Cloud code function
            let rateDictionary = ["muscleGroup" : selectedMuscleGroup]
            PFCloud.callFunctionInBackground("getExercise", withParameters: rateDictionary) { (object, error) -> Void in
                if error == nil {
                    // Got an exercise - create temp values
                    var name = ""
                    var identifier = ""
                    var muscleGroup = ""
                    var desc = ""
                    var picture : UIImage? = nil
                    
                    for (index, value) in (object! as! [String]).enumerate() {
                        print(value)
                        switch index {
                        case 0:
                            name = value
                        case 1:
                            identifier = value
                        case 2:
                            muscleGroup = value
                        case 3:
                            desc = value
                        case 4:
                            self.downloadImage(NSURL(string: value)!, completion: { (image) -> Void in
                                if let image = image {
                                    picture = image
                                    self.exercise.image = picture!
                                }
                                
                                // End ignoring interaction events
                                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                                
                                // Segue to display exercise
                                self.exercise.name = name
                                self.exercise.muscleGroup = muscleGroup
                                self.exercise.identifier = identifier
                                self.exercise.description = desc
                                self.performSegueWithIdentifier("getExercise", sender: self)
                            })
                        default:
                            break
                        }
                    }
                } else {
                    // End ignoring interaction events and present alert
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.presentAlert("Error", alertMessage: "There was an error loading your exercise. Please try again.")
                    self.updateImage(self)
                }
            }
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
        print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else {
                    print(error?.localizedDescription)
                    completion(image: nil)
                    return
                }
                print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
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
            
            // Call Parse Cloud code function
            let rateDictionary = ["muscleGroup" : selectedMuscleGroup]
            PFCloud.callFunctionInBackground("getWorkout", withParameters: rateDictionary) { (object, error) -> Void in
                if error == nil {
                    if let object = object {
                        let exercise_ids = object.valueForKey("exercise_ids") as? [String]
                        let exercise_names = object.valueForKey("exercise_names") as? [String]
                        
                        // Save to class level workout
                        //let generatedWorkout = Workout(name: object.valueForKey("name") as! String, muscleGroup: object.valueForKey("muscle_group") as! String, identifier: "", exerciseIds: object.valueForKey("exercise_ids") as! [String], publicWorkout: true, workoutCode: nil)
                        //print(generatedWorkout)
                        
                        if let exercise_ids = exercise_ids {
                            if let exercise_names = exercise_names {
                                print(exercise_ids)
                                print(exercise_names)
                                self.workout = Workout(name: object.valueForKey("name") as! String, muscleGroup: object.valueForKey("muscle_group") as! String, identifier: object.valueForKey("objectId") as! String, exerciseIds: object.valueForKey("exercise_ids") as! [String], exerciseNames : exercise_names, publicWorkout: true, workoutCode: nil)
                                self.performSegueWithIdentifier("getWorkout", sender: self)
                            }
                        }
                    }
                }
                // End ignoring interaction events and present alert
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                self.updateImage(self)
            }
        }

    }
    
    func updateImage(sender: AnyObject) {
        if isAnimatingImage == false {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: Selector("animateImage"), userInfo: nil, repeats: true)
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
            imageCounter++
        }
        animationImage.image = UIImage(named: "animationFrame\(imageCounter)")
    }
    
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        let successAlert = UIAlertController(title: "Account Created", message: "Your account has been created!", preferredStyle: UIAlertControllerStyle.Alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)

        }))
        signUpController.presentViewController(successAlert, animated: true, completion: nil)
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
        
        let loginVC = LoginViewController()
        loginVC.delegate = self
        
        let signupVC = PFSignUpViewController()
        signupVC.delegate = self
        
        let logo = UIImageView(image: UIImage(named: "loginImage"))
        logo.contentMode = UIViewContentMode.ScaleAspectFill
        logo.sizeToFit()
        signupVC.signUpView?.logo = logo
        
        loginVC.signUpController = signupVC
        
        loginVC.logInView?.dismissButton?.removeFromSuperview()
        
        let logo2 = UIImageView(image: UIImage(named: "loginImage"))
        //logo2.contentMode = UIViewContentMode.ScaleAspectFill
        logo2.sizeToFit()
        loginVC.logInView?.logo = logo2
        
        loginVC.facebookPermissions = ["public_profile", "user_friends", "email"]
        loginVC.fields = [PFLogInFields.UsernameAndPassword, PFLogInFields.LogInButton, PFLogInFields.Facebook, PFLogInFields.SignUpButton, PFLogInFields.PasswordForgotten]
        
        
        self.presentViewController(loginVC, animated: true, completion: nil)

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