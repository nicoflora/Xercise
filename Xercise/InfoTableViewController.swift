//
//  InfoTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit

class InfoTableViewController: UITableViewController {
    
    var infoCategories = [String]()
    var selectedIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let constants = XerciseConstants()
        infoCategories = constants.infoCategories
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
