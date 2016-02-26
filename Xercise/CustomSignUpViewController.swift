//
//  CustomSignUpViewController.swift
//  ReSpy
//
//  Created by Kyle Blazier on 1/16/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import ParseFacebookUtilsV4
import Parse

class CustomSignUpViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var facebookLoginView: UIView!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmPasswordTextField: UITextField!
    @IBOutlet var createAccountButton: UIButton!
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
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        // Add keyboard observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("tapRecognized"))
        self.view.addGestureRecognizer(tapRecognizer)

    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
    }
    
    // MARK: - UITapGestureRecognizer function
    
    func tapRecognized() {
        // If one of the text fields are being edited, resign the keyboard
        if usernameTextField.editing {
            usernameTextField.resignFirstResponder()
        } else if emailTextField.editing {
            emailTextField.resignFirstResponder()
        } else if passwordTextField.editing {
            passwordTextField.resignFirstResponder()
        } else if confirmPasswordTextField.editing {
            confirmPasswordTextField.resignFirstResponder()
        }
    }
    
    // MARK: - UIKeyboard Notification Observer functions
    
    func keyboardWillShow(notification: NSNotification) {
        // Move the hint 50 points above the keyboard
        var info = notification.userInfo!
        let keyboardFrame : CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if pointsPushedUp == 0 {
            let amountHidden = createAccountButton.frame.maxY - keyboardFrame.minY
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
        switch textField.tag {
        case 0:
            emailTextField.becomeFirstResponder()
        case 1:
            passwordTextField.becomeFirstResponder()
        case 2:
            confirmPasswordTextField.becomeFirstResponder()
        case 3:
            confirmPasswordTextField.resignFirstResponder()
            processSignup()
        default:
            return true
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
        switch option {
        case validateOption.username:
            // Validate username
            guard let username = usernameTextField.text else {return nil}
            guard username.characters.count > 3 else {return nil}
            guard username.characters.count <= 20 else {return nil}
            
            if containsSpecialChars(username) {
                return username
            } else {
                return nil
            }            
        case validateOption.password:
            // Validate password
            guard let password = passwordTextField.text else {return nil}
            guard password.characters.count > 5 else {return nil}
            
            if containsSpecialChars(password) {
                return password
            } else {
                return nil
            }
        case validateOption.email:
            // Validate email
            guard let email = emailTextField.text else {return nil}
            guard email.characters.count > 4 else {return nil}
            return email
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
    
    func signupWithParse(username : String, password : String, email : String) {
        let user = PFUser()
        user.username = username
        user.password = password
        user.email = email
        self.displayActivityIndicator()
        user.signUpInBackgroundWithBlock { (success, error) -> Void in
            if error == nil {
                if success {
                    self.dismissSignupVC()
                } else {
                    self.presentAlert("Signup Error", alertMessage: "There was an issue creating your account. Please try again.")
                }
            } else {
                self.presentAlert("Signup Error", alertMessage: (error?.localizedDescription)!)
            }
            self.removeActivityIndicator()
        }
    }
    
    func processSignup() {
        // Signup - validate text
        let username = validateText(validateOption.username)
        if let username = username {
            let password = validateText(validateOption.password)
            if let password = password {
                if let confirmPassword : String = confirmPasswordTextField.text {
                    if password == confirmPassword {
                        let email = validateText(validateOption.email)
                        if let email = email {
                            // All fields validatated, signup
                            signupWithParse(username, password: password, email: email)
                        } else {
                            presentAlert("Email Error", alertMessage: "You have entered an invalid email. Please try again.")
                        }
                    } else {
                        presentAlert("Password Error", alertMessage: "Your passwords do not match. Please try again")
                    }
                } else {
                    presentAlert("Confirm Password Error", alertMessage: "You have entered an invalid confirm password. Please try again")
                }
            } else {
                presentAlert("Password Error", alertMessage: "There was an error with your entered password. Passwords must be at least 6 characters and contain only letters and numbers.")
            }
        } else {
            presentAlert("Username Error", alertMessage: "There was an error with your entered username. Usernames must be at least 4 characters and contain only letters and numbers.")
        }
    }
    
    func loginWithFacebook(accessToken : FBSDKAccessToken) {
        PFFacebookUtils.logInInBackgroundWithAccessToken(accessToken) { (user, error) -> Void in
            if user != nil {
                self.dismissSignupVC()
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
    
    func displayActivityIndicator() {
        self.view.addSubview(activityIndicator)
        self.view.bringSubviewToFront(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func removeActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    
    func dismissSignupVC() {
        self.performSegueWithIdentifier("successfulSignup", sender: self)
    }

    // MARK: - IBAction Functions
    
    @IBAction func createAccountButtonPressed(sender: AnyObject) {
        processSignup()
    }
    
    @IBAction func toggleLoginSignupButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
