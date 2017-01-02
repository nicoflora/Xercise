//
//  AddExerciseFromSavedTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/2/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData

class AddExerciseFromSavedTableViewController: UITableViewController {
    
    var exercisesToAdd = [Entry]()
    var savedExercises = [Entry]()
    let dataMgr = DataManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getMyXercises()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getMyXercises() {
        savedExercises.removeAll()
        savedExercises = dataMgr.getMyExercises()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if savedExercises.count > 0 {
            return savedExercises.count
        } else {
            return 1
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        // Save exercises to pass back
        if exercisesToAdd.count > 0 {
            dataMgr.storeEntriesInDefaults(exercisesToAdd, key: "exercisesToAdd")
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        
        if savedExercises.count > 0 {
            cell.textLabel?.text = savedExercises[indexPath.row].title
            // If cell has been selected, display a checkmark
            for exToAdd in exercisesToAdd {
                if exToAdd.identifier == savedExercises[indexPath.row].identifier {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
            }
        } else {
            cell.textLabel?.text = "You have no saved exercises!"
        }
        
        cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if savedExercises.count > 0 {
            let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
            let anEntry = savedExercises[indexPath.row]
            if selectedCell.accessoryType == UITableViewCellAccessoryType.Checkmark {
                // Already in exercise to add, remove accessory type and remove
                selectedCell.accessoryType = UITableViewCellAccessoryType.None
                for (index,exercise) in exercisesToAdd.enumerate() {
                    if exercise.identifier == anEntry.identifier {
                        exercisesToAdd.removeAtIndex(index)
                    }
                }
            } else {
                // Add to array, add accessory type
                exercisesToAdd.append(anEntry)
                selectedCell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
        }
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
