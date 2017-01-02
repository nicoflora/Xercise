//
//  InitialViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 2/25/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
    
    var loggedIn = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Check if user is logged in
        //checkIfLoggedIn()
        
        delay(0.2) {
            dispatch_async(dispatch_get_main_queue(), { 
                self.performSegueWithIdentifier("loggedIn", sender: self)
            })
        }
    }
    
    func checkIfLoggedIn() {
        
        // Disabling authentication
        loggedIn = true
        
//        if PFUser.currentUser() != nil {
//            loggedIn = true
//        }
    }
    
    override func viewDidAppear(animated: Bool) {
        //checkIfLoggedIn()
        
//        if loggedIn {
//            self.performSegueWithIdentifier("loggedIn", sender: self)
//        } else {
//            self.performSegueWithIdentifier("notLoggedIn", sender: self)
//        }
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

extension UIViewController {
    func delay(delay : Double, closure: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
}
