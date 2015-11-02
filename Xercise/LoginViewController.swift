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

class LoginViewController: PFLogInViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //self.logInView?.dismissButton?.removeFromSuperview()
        
        //self.logInView?.logo?.frame = CGRectMake(0, 0, 200, 200)
        
        //self.logInView?.logo? = UIImageView(image: UIImage(named: "iTunesArtwork.png"))
        
        //self.fields = PFLogInFields.UsernameAndPassword | PFLogInFields.LogInButton | PFLogInFields.Facebook | PFLogInFields.Twitter | PFLogInFields.PasswordForgotten | PFLogInFields.SignUpButton
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
