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

class NewXerciseViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    @IBOutlet var animationImage: UIImageView!
    @IBOutlet var selectMuscleGroupBtn: UIButton!
    
    var imageCounter = 1
    var isAnimatingImage = false
    var timer = NSTimer()
    var muscleGroups = [String]()
    
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
        timer.invalidate()
    }
    
    @IBAction func selectMuscleGroupBtnPressed(sender: AnyObject) {
        
        if muscleGroups.count == 5 {
            let actionSheet = UIAlertController(title: nil, message: "Select a muscle group:", preferredStyle: UIAlertControllerStyle.ActionSheet)
            actionSheet.addAction(UIAlertAction(title: muscleGroups[0], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[0])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[1], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[1])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[2], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[2])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[3], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[3])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: muscleGroups[4], style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.selectMuscleGroupBtn.setTitle("Muscle Group: \(self.muscleGroups[4])", forState: UIControlState.Normal)
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func getExerciseButtonPressed(sender: AnyObject) {
        // Start animation
        updateImage(self)
        
        // Display activity indicator
        
        // Fetch an exercise & perform segue
        //self.performSegueWithIdentifier("getExercise", sender: self)
    }
    
    @IBAction func getWorkoutButtonPressed(sender: AnyObject) {
        // Start animation
        updateImage(self)
        
        // Display activity indicator
        
        // Fetch a workout & perform segue
        //self.performSegueWithIdentifier("getWorkout", sender: self)

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
        let confirmLogout = UIAlertController(title: "Logout?", message: "Are you sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
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
        signupVC.signUpView?.logo = logo
        
        loginVC.signUpController = signupVC
        
        loginVC.logInView?.dismissButton?.removeFromSuperview()
        
        let logo2 = UIImageView(image: UIImage(named: "loginImage"))
        logo2.contentMode = UIViewContentMode.ScaleAspectFill
        loginVC.logInView?.logo = logo2
        
        //loginVC.facebookPermissions = ["friends_about_me"]
        
        //loginVC.fields = (PFLogInFields.UsernameAndPassword | PFLogInFields.LogInButton | PFLogInFields.Facebook | PFLogInFields.Twitter | PFLogInFields.SignUpButton | PFLogInFields.PasswordForgotten)
        
        self.presentViewController(loginVC, animated: true, completion: nil)

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}