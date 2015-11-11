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
    
    func saveWorkoutToDevice(workoutName : String, workoutMuscleGroup : String, id : String, exerciseIDs : NSData, publicWorkout : Bool, completion : (success : Bool) -> Void) {
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let newWorkout = NSEntityDescription.insertNewObjectForEntityForName("Workout", inManagedObjectContext: context)
        newWorkout.setValue(workoutName, forKey: "name")
        newWorkout.setValue(id, forKey: "identifier")
        newWorkout.setValue(exerciseIDs, forKey: "exercise_ids")
        newWorkout.setValue(workoutMuscleGroup, forKey: "muscle_group")
        newWorkout.setValue(publicWorkout, forKey: "publicWorkout")
        do {
            try context.save()
            completion(success: true)
        } catch {
            completion(success: false)
        }
    }
    
    func saveWorkoutToParse(workoutName : String, workoutMuscleGroup : String, id : String, exerciseIDs : NSData, completion : (success : Bool) -> Void) {
        
        // Create Parse object to save
        let workout = PFObject(className: "Workout")
        workout["name"] = workoutName
        workout["identifier"] = id
        workout["exercise_ids"] = exerciseIDs
        workout["muscle_group"] = workoutMuscleGroup
        workout.saveInBackgroundWithBlock { (success, error) -> Void in
            if error == nil {
                completion(success: true)
            } else {
                completion(success: false)
            }
        }
    }
    
    func checkParseExerciseAvailablity(ids : [String], completion : (success : Bool) -> Void) {
        var completionSuccess = true
        for exerciseID in ids {
            let query = PFQuery(className: "Exercise")
            query.whereKey("identifier", equalTo: exerciseID)
            query.findObjectsInBackgroundWithBlock({ (objects : [PFObject]?, error: NSError?) -> Void in
                if objects?.count == 0 {
                    // Not in Parse database, add to Parse
                    if let exerciseToAdd : Exercise = self.getExerciseByID(exerciseID) {
                        // Got Exercise from Core Data - now add to Parse
                        if let img = UIImageJPEGRepresentation(exerciseToAdd.image, 0.5) {
                            self.saveExerciseToParse(exerciseToAdd.name, id: exerciseToAdd.identifier, muscleGroup: exerciseToAdd.muscleGroup, image: img, exerciseDescription: exerciseToAdd.description, completion: { (success) -> Void in
                                if success == false {
                                    // erorr saving to Parse
                                    completionSuccess = false
                                }
                            })
                        }
                    }
                }
            })
        }
        if completionSuccess {
            completion(success: true)
        } else {
            completion(success: false)
        }
    }
    
    func getWorkoutByID(id : String) -> Workout? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Workout(name: "", muscleGroup: "", identifier: "", exerciseIds: [""], publicWorkout: false, workoutCode: nil)
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
                    entryToReturn = Workout(name: result.valueForKey("name")! as! String, muscleGroup: result.valueForKey("muscle_group")! as! String, identifier: result.valueForKey("identifier")! as! String, exerciseIds: exercises, publicWorkout: result.valueForKey("publicWorkout") as! Bool, workoutCode: result.valueForKey("workoutCode") as! String?)
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
    
    func queryForItemByID(id : String, entityName : String, completion : (success : Bool) -> Void) {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestExercise = NSFetchRequest(entityName: entityName)
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            if results.count > 0 {
                completion(success: true)
            } else {
                completion(success: false)
            }
        } catch {
            print("There was an error fetching the \(entityName) by ID")
            completion(success: false)
        }
    }
    
    func queryForWorkoutCode(id : String) -> String {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var groupCode = ""
        let requestExercise = NSFetchRequest(entityName: "Workout")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    groupCode = result.valueForKey("workoutCode")! as! String
                }
            }
        } catch {
            print("There was an error fetching the workout code by ID")
        }
        return groupCode
    }
    
    func queryParseForWorkoutCode(id : String, completion : (success : Bool) -> Void) {
        var objectID = ""
        var failure = true
        let query = PFQuery(className: "Workout")
        query.whereKey("identifier", equalTo: id)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                // Successful query - get objectID
                if let objects = objects {
                    for object in objects {
                        failure = false
                        objectID = object.objectId!
                    }
                }
                if !failure {
                    self.addGroupCodeByID(id, code: objectID, completion: { (success) -> Void in
                        if success {
                            completion(success: true)
                        } else {
                            completion(success: false)
                        }
                    })
                    
                } else {
                    completion(success: false)
                }

            }
        }
    }
    
    func queryParseForWorkoutFromGroupCode(code : String, completion : (workoutFromCode : Workout?) -> Void) { //) -> Workout? {
        var workout = Workout(name: "", muscleGroup: "", identifier: "", exerciseIds: [""], publicWorkout: true, workoutCode: "")
        let query = PFQuery(className: "Workout")
        query.whereKey("objectId", equalTo: code)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                // Successful query - get workout data
                if let objects = objects {
                    if objects.count > 0 {
                        for object in objects {
                            let exerciseIds = self.unarchiveArray(object["exercise_ids"] as! NSData)
                            workout = Workout(name: object["name"]! as! String, muscleGroup: object["muscle_group"]! as! String, identifier: object["identifier"]! as! String, exerciseIds: exerciseIds, publicWorkout: true, workoutCode: object.objectId)
                            completion(workoutFromCode: workout)
                        }
                    } else {
                        completion(workoutFromCode: nil)
                        return
                    }
                } else {
                    completion(workoutFromCode: nil)
                    return
                }
            } else {
                completion(workoutFromCode: nil)
                return
            }
        }
    }

    func queryParseForExercisesFromGroupCode(ids : [String], completion : (success : Bool) -> Void) {
        var failure = false
        var successes = 0
        for id in ids {
            let query = PFQuery(className: "Exercise")
            query.whereKey("identifier", equalTo: id)
            query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                if error == nil {
                    // Successful query - store exercises on device
                    if let objects = objects {
                        failure = false
                        for object in objects {
                            // Get image data
                            successes++
                            if let picture = object["image"] as? PFFile {
                                picture.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                                    if error == nil {
                                        // Successfully recieved the imageData - Check if exercise is already stored on device
                                        self.queryForItemByID(object["identifier"] as! String, entityName: "Exercise", completion: { (success) -> Void in
                                            if !success {
                                                // Exercise has not yet been stored, store on device now
                                                self.saveExerciseToDevice(object["name"] as! String, id: object["identifier"] as! String, muscleGroup: object["muscle_group"] as! String, image: imageData!, exerciseDescription: object["exercise_desc"] as! String, completion: { (success) -> Void in
                                                    if !success {
                                                        completion(success: false)
                                                        return
                                                    } else {
                                                        // If we every save has been successful and we have gone through all exercises, we are done
                                                        if failure == false && successes == ids.count {
                                                            // All exercises were retrieved and saved to the device
                                                            completion(success: true)
                                                        } else if successes == ids.count {
                                                            completion(success: false)
                                                        }
                                                    }
                                                })
                                            }
                                        })
                                    } else {
                                        completion(success: false)
                                        return
                                    }
                                })
                            } else {
                                completion(success: false)
                                return
                            }
                        }
                    } else {
                        completion(success: false)
                        return
                    }
                } else {
                    completion(success: false)
                    return
                }
            }
        }
    }
    
    func addGroupCodeByID(id : String, code : String, completion : (success : Bool) -> Void) {
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestWorkout = NSFetchRequest(entityName: "Workout")
        requestWorkout.predicate = NSPredicate(format: "identifier = %@", id)
        requestWorkout.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestWorkout)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    result.setValue(code, forKey: "workoutCode")
                    result.setValue(true, forKey: "publicWorkout")
                    do {
                        try context.save()
                        completion(success: true)
                    } catch {
                        completion(success: false)
                    }
                    
                }
            }
        } catch {
            print("There was an error adding the group code by ID")
            completion(success: false)
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
            completion(success: false)
        }
    }
}