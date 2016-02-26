//
//  MacrosTableViewController.swift
//  Xercise
//
//  Created by Nico Flora on 2/23/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit

class MacrosTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 25
        }else{
            return 50
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("macroHeader", forIndexPath: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.mealName.text = "Breakfast"
            cell.mealCarbs.text = "23g"
            cell.mealFats.text = "18g"
            cell.mealProteins.text = "7g"
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.backgroundColor = UIColor.greenColor()
            cell.mealName.text = "Total"
            cell.mealName.font = UIFont.systemFontOfSize(15)
            cell.mealCarbs.text = "23g"
            cell.mealFats.text = "18g"
            cell.mealProteins.text = "7g"
            return cell
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.backgroundColor = UIColor.purpleColor()
            cell.mealName.text = "Goal"
            cell.mealName.font = UIFont.systemFontOfSize(15)
            cell.mealCarbs.text = "23g"
            cell.mealFats.text = "18g"
            cell.mealProteins.text = "7g"
            return cell
        default:
            return UITableViewCell()
        }
        
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
