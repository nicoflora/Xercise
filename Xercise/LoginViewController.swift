//
//  LoginViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 10/31/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import FBSDKLoginKit
import ParseFacebookUtilsV4

class LoginViewController: PFLogInViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fields = [PFLogInFields.UsernameAndPassword, PFLogInFields.LogInButton, PFLogInFields.Facebook, PFLogInFields.SignUpButton, PFLogInFields.PasswordForgotten]
        logInView?.facebookButton?.addTarget(self, action: "loginWithFacebook", forControlEvents: UIControlEvents.TouchUpInside)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginWithFacebook() {
        /*let loginManager = FBSDKLoginManager()
        loginManager.logInWithReadPermissions(["public_profile", "user_friends", "email"], fromViewController: self) { (result, error) -> Void in
            if error != nil {
                print("error")
            } else if result.isCancelled {
                print("Cancelled")
            } else {
                // Logged In
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }*/
        
        PFFacebookUtils.logInInBackgroundWithReadPermissions(["public_profile", "user_friends", "email"]) { (user, error) -> Void in
            if let user = user {
                // Successful login
                print("logged in")
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                print("not logged in")
                print(error)
                self.presentAlert("Not Logged In", alertMessage: "You have not been signed in with Facebook. You can either create an account or signup with Facebook.")
            }
        }
    }

    func presentAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
