//
//  CustomLoginViewController.swift
//  ReSpy
//
//  Created by Kyle Blazier on 1/15/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import ParseFacebookUtilsV4
import Parse

enum validateOption {
    case username
    case password
    case email
}

class CustomLoginViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {
    
    @IBOutlet var facebookLoginView: UIView!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var toggleLoginSignupButton: UIButton!
    @IBOutlet var goButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    let dataMgr = DataManager()
    var facebookButton = FBSDKLoginButton(frame: CGRectZero)
    var signupActive = false
    var pointsPushedUp : CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Facebook Login Button
        facebookButton.frame = CGRectMake(facebookLoginView.bounds.minX, facebookLoginView.bounds.minY,facebookLoginView.bounds.width, 40)
        facebookButton.delegate = self
        facebookLoginView.addSubview(facebookButton)
        
        // Setup textfield delegates
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // Add keyboard observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("tapRecognized"))
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITapGestureRecognizer function
    
    func tapRecognized() {
        if usernameTextField.editing {
            // If the username is being edited, resign the keyboard
            usernameTextField.resignFirstResponder()
        } else if passwordTextField.editing {
            // If the password is being edited, resign the keyboard
            passwordTextField.resignFirstResponder()
        }
    }
    
    // MARK: - UIKeyboard Notification Observer functions
    
    func keyboardWillShow(notification: NSNotification) {
        // Move the hint 50 points above the keyboard
        var info = notification.userInfo!
        let keyboardFrame : CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if pointsPushedUp == 0 {
            let amountHidden = goButton.frame.maxY - keyboardFrame.minY
            // If the go button is hidden, push up the view
            if amountHidden >= 0 {
                pointsPushedUp = amountHidden
                UIView.animateWithDuration(0.1) { () -> Void in
                    //self.hint.frame = CGRectMake(0, keyboardFrame.origin.y - 50, UIScreen.mainScreen().bounds.width, 30)
                    self.view.frame = CGRectMake(0, self.view.frame.minY - amountHidden, self.view.bounds.width, self.view.bounds.height)
                }
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // If there is a saved location of the hint before it was moved,
        //  reset it's y value to that value
        if pointsPushedUp != 0 {
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                //self.hint.frame = CGRectMake(0, self.hintYBeforeKeyboardShow, self.hint.bounds.width, self.hint.bounds.height)
                self.view.frame = CGRectMake(0, self.view.frame.minY + (self.pointsPushedUp), self.view.bounds.width, self.view.bounds.height)
                self.pointsPushedUp = 0
            })
        }
    }

    
    
    // MARK: - UITextFieldDelegate Functions
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.tag == 0 {
            passwordTextField.becomeFirstResponder()
        } else {
            passwordTextField.resignFirstResponder()
            processLogin()
        }
        return true
    }
    
    // MARK: - FBSDKLoginButtonDelegate Functions
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error == nil {
            if !result.isCancelled {
                loginWithFacebook(result.token)
            }
        } else {
            presentAlert("Facebook Login Error", alertMessage: error.localizedDescription)
        }
    }
    
    func loginButtonWillLogin(loginButton: FBSDKLoginButton!) -> Bool {
        return true
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("logged out")
    }
    
    func validateText(option : validateOption) -> String? {
        if option == validateOption.username {
            // Validate username
            guard let username = usernameTextField.text else {return nil}
            guard username.characters.count > 3 else {return nil}
            guard username.characters.count <= 20 else {return nil}

            if containsSpecialChars(username) {
                return username
            } else {
                return nil
            }
        } else if option == validateOption.password {
            // Validate password
            guard let password = passwordTextField.text else {return nil}
            guard password.characters.count > 5 else {return nil}
            
            if containsSpecialChars(password) {
                return password
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func containsSpecialChars(testString : String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: ".*[^a-z0-9].*", options: NSRegularExpressionOptions.CaseInsensitive)
            if regex.firstMatchInString(testString, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, testString.characters.count)) != nil {
                return false
            }
            return true
        } catch {
            print("Error initializing regex")
            return false
        }
    }
    
    func loginWithParse(username : String, password : String) {
        PFUser.logInWithUsernameInBackground(username, password: password) { (user, error) -> Void in
            if error == nil {
                if user != nil {
                    self.dismissLoginVC()
                } else {
                    self.presentAlert("Login Error", alertMessage: "There was an issue logging you in. Please try again.")
                }
            } else {
                self.presentAlert("Login Error", alertMessage: (error?.localizedDescription)!)
            }
        }
    }
    
    func processLogin() {
        if !signupActive {
            // Login - validate text
            if let username = validateText(validateOption.username) {
                if let password = validateText(validateOption.password) {
                    // Username and password validated - try to log the user in
                    loginWithParse(username, password: password)
                } else {
                    presentAlert("Password Error", alertMessage: "There was an error with your entered password. Passwords must be at least 6 characters and contain only letters and numbers.")
                }
            }  else {
                presentAlert("Username Error", alertMessage: "There was an error with your entered username. Usernames must be at least 4 characters and contain only letters and numbers.")
            }
        }
    }
    
    
    @IBAction func goButtonPressed(sender: AnyObject) {
        processLogin()
    }

    
    @IBAction func toggleLoginSignupButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("showSignup", sender: self)
    }
    
    
    @IBAction func resetPasswordButtonPressed(sender: AnyObject) {
        let actionSheet = UIAlertController(title: nil, message: "Are you sure you want to reset your password?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Reset", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            // Reset password
            let getPasswordAlert = UIAlertController(title: "Reset Password", message: "Enter the email associated with your account to reset your password.", preferredStyle: UIAlertControllerStyle.Alert)
            getPasswordAlert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                textField.placeholder = "Email Address"
                textField.autocorrectionType = UITextAutocorrectionType.No
                textField.autocapitalizationType = UITextAutocapitalizationType.None
                textField.tag = -1
            })
            getPasswordAlert.addAction(UIAlertAction(title: "Reset", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                // Try to retrieve email
                let textfield = getPasswordAlert.textFields![0] as UITextField
                // If there was an account name entered
                if let text = textfield.text {
                    if text != "" {
                        PFUser.requestPasswordResetForEmailInBackground(text, block: { (success, error) -> Void in
                            if error == nil {
                                if success {
                                    self.presentAlert("Password Reset", alertMessage: "An email has been sent to you with instructions for resetting your password.")
                                } else {
                                    self.presentAlert("Error", alertMessage: "There was an error resetting your password, please try again")
                                }
                            } else {
                                self.presentAlert("Password Reset Error", alertMessage: (error?.localizedDescription)!)
                            }
                        })
                    }
                }
                // Reset password using retrieved email
            }))
            getPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(getPasswordAlert, animated: true, completion: nil)
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
    func loginWithFacebook(accessToken : FBSDKAccessToken) {
        PFFacebookUtils.logInInBackgroundWithAccessToken(accessToken) { (user, error) -> Void in
            if user != nil {
                // Successful login with facebook
                self.dismissLoginVC()
            } else {
                print(error)
                self.presentAlert("Not Logged In", alertMessage: "You have not been signed in with Facebook. You can either create an account or signup with Facebook.")
            }
        }
    }

    // MARK: - Utility Functions
    
    func presentAlert(alertTitle : String, alertMessage : String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func dismissLoginVC() {
        guard let initialVC = self.storyboard?.instantiateInitialViewController()
            
        else {
            self.performSegueWithIdentifier("successfulLogin", sender: self)
            return
        }
        self.presentViewController(initialVC, animated: false, completion: nil)
    }

    func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
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
