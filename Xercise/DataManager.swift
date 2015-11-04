//
//  DataManager.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/2/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import Foundation
import CoreData

class DataManager {
    
    let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
    func storeEntriesInDefaults(arr : [Entry], key : String) {
        
        let archiveKey = NSKeyedArchiver.archivedDataWithRootObject(arr)
        
        defaults.setObject(archiveKey, forKey: key)
        
    }
    
    func retrieveEntriesFromDefaults(key : String) -> [Entry] {
        
        let storedAccounts = defaults.objectForKey(key) as? NSData
        
        if let storedAccounts = storedAccounts {
            
            let theAccounts = NSKeyedUnarchiver.unarchiveObjectWithData(storedAccounts) as? [Entry]
            
            if let theAccounts = theAccounts {
                
                // Accounts are stored in NSUserDefaults
                if theAccounts.count > 0 {
                    
                    return theAccounts
                    
                }
            }
        }
        return []
    }
    
    func archiveArray(arr : [String]) -> NSData {
        
        let archiveKey = NSKeyedArchiver.archivedDataWithRootObject(arr)
        
        return archiveKey
    }
    
    func unarchiveArray(archivedData : NSData) -> [String] {
        let unarchivedData = NSKeyedUnarchiver.unarchiveObjectWithData(archivedData) as? [String]
        if let data = unarchivedData {
            return data
        } else {
            return []
        }
    }
    
    func getExerciseByID(id : String) -> Entry? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Entry(exerciseTitle: "", exerciseIdentifer: "")
        
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    entryFound = true
                    entryToReturn = Entry(exerciseTitle: result.valueForKey("name")! as! String, exerciseIdentifer: result.valueForKey("identifier")! as! String)
                }
            }
        } catch {
            print("There was an error fetching the exercise by ID")
        }
        
        if entryFound {
            return entryToReturn
        } else {
            return nil
        }
    }
    
    func getWorkoutByID(id : String) -> Entry? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Entry(exerciseTitle: "", exerciseIdentifer: "")
        
        let requestExercise = NSFetchRequest(entityName: "Workout")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    entryFound = true
                    entryToReturn = Entry(exerciseTitle: result.valueForKey("name")! as! String, exerciseIdentifer: result.valueForKey("identifier")! as! String)
                }
            }
        } catch {
            print("There was an error fetching the workout by ID")
        }
        
        if entryFound {
            return entryToReturn
        } else {
            return nil
        }
    }
    
    
    func getMyWorkouts() -> [Entry] {
        
        var workouts = [Entry]()
        let context : NSManagedObjectContext = appDel.managedObjectContext
        
        let requestWorkout = NSFetchRequest(entityName: "Workout")
        requestWorkout.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestWorkout)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    workouts.append(Entry(exerciseTitle: result.valueForKey("name")! as! String, exerciseIdentifer: result.valueForKey("identifier")! as! String))
                    
                }
            }
        } catch {
            print("There was an error fetching the workouts")
        }
        
        return workouts
    }
    
    func getMyExercises() -> [Entry] {
        
        var exercises = [Entry]()
        let context : NSManagedObjectContext = appDel.managedObjectContext
        
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    exercises.append(Entry(exerciseTitle: result.valueForKey("name")! as! String, exerciseIdentifer: result.valueForKey("identifier")! as! String))
                }
            }
        } catch {
            print("There was an error fetching exercises")
        }
        
        return exercises
    }



}