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
import Parse

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
    
    func getEntryByID(id : String, entityName : String) -> Entry? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Entry(exerciseTitle: "", exerciseIdentifer: "")
        
        if id != "" && entityName != "" {
            let requestExercise = NSFetchRequest(entityName: entityName)
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
                print("There was an error fetching the entry by ID")
            }
            
            if entryFound {
                return entryToReturn
            } else {
                return nil
            }
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
    
    func saveExerciseToDevice(name : String, id : String, muscleGroup : String, image : NSData, exerciseDescription : String, completion : (success : Bool) -> Void) {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext

        let newExercise = NSEntityDescription.insertNewObjectForEntityForName("Exercise", inManagedObjectContext: context)
        newExercise.setValue(name, forKey: "name")
        newExercise.setValue(muscleGroup, forKey: "muscle_group")
        newExercise.setValue(image, forKey: "image")
        newExercise.setValue(exerciseDescription, forKey: "exercise_desc")
        newExercise.setValue(id, forKey: "identifier")
        
        do {
            try context.save()
            completion(success: true)
        } catch {
            print("There was an error saving the exercise")
            completion(success: false)
        }
    }
    
    func saveExerciseToParse(name : String, id : String, muscleGroup : String, image : NSData, exerciseDescription : String, completion : (success : Bool) -> Void) {
                
        // Parse exercise object
        let exercise = PFObject(className: "Exercise")
        
        exercise["name"] = name
        exercise["muscle_group"] = muscleGroup
        exercise["exercise_desc"] = exerciseDescription
        exercise["identifier"] = id
        
        let imageFile = PFFile(name: "image.jpeg", data: image)
        exercise["image"] = imageFile
        
    
        exercise.saveInBackgroundWithBlock { (success, error) -> Void in
            if error == nil {
                completion(success: true)
            } else {
                completion(success: false)
            }
        }
    }
    
    func getWorkoutByID(id : String) -> Workout? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Workout(name: "", muscleGroup: "", identifier: "", exerciseIds: [""])
        
        let requestExercise = NSFetchRequest(entityName: "Workout")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    entryFound = true
                    // Unarchive exercise IDs
                    let exercises : [String] =  unarchiveArray(result.valueForKey("exercise_ids")! as! NSData)
                    // Create the workout object to be returned
                    entryToReturn = Workout(name: result.valueForKey("name")! as! String, muscleGroup: result.valueForKey("muscle_group")! as! String, identifier: result.valueForKey("identifier")! as! String, exerciseIds: exercises)
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
    
    func getExerciseByID(id : String) -> Exercise? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Exercise(name: "", muscleGroup: "", identifier: "", description: "", image: UIImage())
        
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    entryFound = true
                    // Create image from NSData stored in Core Data
                    let image : UIImage = UIImage(data: result.valueForKey("image")! as! NSData)!
                    // Create the Exercise object to be returned
                    entryToReturn = Exercise(name: result.valueForKey("name")! as! String, muscleGroup: result.valueForKey("muscle_group")! as! String, identifier: result.valueForKey("identifier")! as! String, description: result.valueForKey("exercise_desc")! as! String, image: image)
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
    
    
    func deleteItemByID(id : String, entityName : String, completion : (success : Bool) -> Void) {

        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestExercise = NSFetchRequest(entityName: entityName)
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    // Delete from Core Data
                    context.deleteObject(result)
                    do {
                        try context.save()
                        completion(success: true)
                    } catch {
                        print("There was an error saving after delection of a \(entityName)")
                        completion(success: false)
                    }
                }
            }
        } catch {
            print("There was an error deleting the \(entityName) by ID")
        }
    }
}

class Exercise {
    var name : String
    var muscleGroup : String
    var identifier : String
    var description : String
    var image : UIImage
    
    init(name : String, muscleGroup : String, identifier : String, description : String, image : UIImage) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.identifier = identifier
        self.description = description
        self.image = image
    }
}

class Workout {
    var name : String
    var muscleGroup : String
    var identifier : String
    var exerciseIDs : [String]
    
    init(name : String, muscleGroup : String, identifier : String, exerciseIds : [String]) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.identifier = identifier
        self.exerciseIDs = exerciseIds
    }
}