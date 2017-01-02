//
//  InfoTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import MessageUI

class InfoTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    var infoCategories = [String]()
    var selectedIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let constants = XerciseConstants.sharedInstance
        infoCategories = constants.infoCategories
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func contactUsButtonPressed(sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["xercisefitnessapp@gmail.com"])
            mail.setSubject("Xercise Feedback")
            mail.navigationBar.tintColor = UIColor.whiteColor()
            self.presentViewController(mail, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Unable to send mail", message: "We were unable to access any email accounts on your device. Please add an account and try again!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true) {
            //if result == MFMailComposeResult.sent {
//            if result == MFMailComposeResultSent {
//                let alert = UIAlertController(title: "Thank you!", message: "Thank you for your feedback. Our team will review your comments shortly!", preferredStyle: UIAlertControllerStyle.Alert)
//                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoCategories.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = infoCategories[indexPath.row]
        cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        performSegueWithIdentifier("expandedInfo", sender: self)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "expandedInfo" {
            let destinationVC = segue.destinationViewController as! ExpandedInfoViewController
            if selectedIndex != -1 {
                destinationVC.selectedCategory = selectedIndex
            }
        }
    }
    
}
