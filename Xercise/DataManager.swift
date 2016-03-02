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
    
    var updateXercisesDelegate : XercisesUpdatedDelegate?
    
    // Arrays to cache Parse query results
    var exercisesForMuscleGroup = [String : [PFObject]]()
    var workoutsMatchingMuscleGroup = [String : [PFObject]]()
    
    
    // MARK: - Utility Functions
    
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
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL, completion : (image : UIImage?) -> Void) {
        print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else {
                    print(error?.localizedDescription)
                    completion(image: nil)
                    return
                }
                print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
                completion(image: UIImage(data: data)!)
            }
        }
    }

    // MARK: - Core Data Functions
    
    func getEntryByID(id : String, entityName : String) -> Entry? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        if id != "" && entityName != "" {
            let requestExercise = NSFetchRequest(entityName: entityName)
            requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
            requestExercise.returnsObjectsAsFaults = false
            do {
                let results = try context.executeFetchRequest(requestExercise)
                if results.count > 0 {
                    guard let result = results.first as? NSManagedObject else {return nil}
                    guard let title = result.valueForKey("name") as? String else {return nil}
                    guard let id = result.valueForKey("identifier") as? String else {return nil}
                    guard let muscle_group = result.valueForKey("muscle_group") as? NSData else {return nil}
                    let muscleGroup = unarchiveArray(muscle_group)
                    guard let mainMuscleGroup = muscleGroup.first else {return nil}
                    return Entry(exerciseTitle: title, exerciseIdentifer: id, muscle_group: mainMuscleGroup)
                }
            } catch {
                print("There was an error fetching the entry by ID")
            }
        }
        return nil
    }
    
    func getMyWorkouts() -> [Entry] {
        
        var workouts = [Entry]()
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestWorkout = NSFetchRequest(entityName: "Workout")
        requestWorkout.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestWorkout)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return []}
                for result in results {
                    guard let title = result.valueForKey("name") as? String else {continue}
                    guard let id = result.valueForKey("identifier") as? String else {continue}
                    guard let muscleGroups = result.valueForKey("muscle_group") as? NSData else {continue}
                    let muscleGroup = unarchiveArray(muscleGroups)
                    guard muscleGroup.count > 0 else {continue}
                    guard let mainMuscleGroup = muscleGroup.first else {continue}
                    workouts.append(Entry(exerciseTitle: title, exerciseIdentifer: id, muscle_group: mainMuscleGroup))
                }
            }
        } catch {
            print("There was an error fetching the workouts")
        }
        return workouts
    }
    
    func resetMyMacros(){
        var macros = [Macro]()
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestMacro = NSFetchRequest(entityName: "Macro_Meal")
        requestMacro.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestMacro)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return}
                for result in results {
                    context.deleteObject(result)
                }
                try context.save()
            }
        }catch{
            print("Error resetting macros")
            return
        }

    }
    
    func getMyMacros() -> [Macro]? {
        
        var macros = [Macro]()
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestMacro = NSFetchRequest(entityName: "Macro_Meal")
        requestMacro.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestMacro)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return nil}
                for result in results {
                    guard let name = result.valueForKey("name") as? String else {continue}
                    guard let expiration = result.valueForKey("expiration") as? NSDate else {continue}
                    guard let carbs = result.valueForKey("carbs") as? Int else {continue}
                    guard let fats = result.valueForKey("fats") as? Int else {continue}
                    guard let proteins = result.valueForKey("proteins") as? Int else {continue}
                    guard let id = result.valueForKey("id") as? String else {continue}
                    
                    
                    /* DATE EXPIRATION DOES NOT WORK FOR TIMEZONES
                    let date = NSDate()
                    let calendar = NSCalendar.currentCalendar()
                    let components = calendar.components(NSCalendarUnit.Hour, fromDate: date)
                    let hour = components.hour
                    
                    if let endOfDay = expiration.endOfDay {
                        let endTime = endOfDay.addHours(3)
                        //var componentsofEndOfDay = calendar.components(NSCalendarUnit.Hour, fromDate: endOfDay)
                        //componentsofEndOfDay.hour += 3
                        print("end day at 3 AM: \(endTime)")
                        
                        if date.isGreaterThanDate(endTime) {
                            print("macro meal is expired")
                        } else {
                            print("meal not expired")
                            macros.append(Macro(name: name, carbs: carbs, fats: fats, proteins: proteins, expiration: expiration, id : id))
                        }
                        
                        
                    }*/
                    
                      macros.append(Macro(name: name, carbs: carbs, fats: fats, proteins: proteins, expiration: expiration, id : id))
                    
                }
                guard macros.count > 0 else {return nil}
                return macros
                
            }
        } catch {
            print("There was an error fetching exercises")
        }
        
        
        return nil
    }
    
    func saveMacroGoalToDevice(goal : MacroGoal){
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let deleteMacroGoal = NSFetchRequest(entityName: "Macro_Goal")
        deleteMacroGoal.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(deleteMacroGoal)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return}
                for result in results{
                     context.deleteObject(result)
                }
                try context.save()
                print("delete successful")
            }
        }catch{
            print("delete unsuccessful")
        }

        let newMacro = NSEntityDescription.insertNewObjectForEntityForName("Macro_Goal", inManagedObjectContext: context)
        newMacro.setValue(goal.carbs, forKey: "carbs")
        newMacro.setValue(goal.fats, forKey: "fats")
        newMacro.setValue(goal.proteins, forKey: "proteins")
        
        do {
            try context.save()
            print("save successful")
        } catch {
            print("There was an error saving the goal")
        }
    }
    
    func getMyGoal() -> MacroGoal?{
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestMacroGoal = NSFetchRequest(entityName: "Macro_Goal")
        requestMacroGoal.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestMacroGoal)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return nil}
                guard let result = results.first else {return nil}
                guard let carbs = result.valueForKey("carbs") as? Int else {return nil}
                guard let fats = result.valueForKey("fats") as? Int else {return nil}
                guard let proteins = result.valueForKey("proteins") as? Int else {return nil}
                return MacroGoal(carbs: carbs, fats: fats, proteins: proteins)
            }
        } catch {
            print("There was an error fetching goal")
        }
        return nil
    }
    
    func updateMacrosToDevice(macro : Macro){
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestMacro = NSFetchRequest(entityName: "Macro_Meal")
        requestMacro.predicate = NSPredicate(format: "id = %@", macro.id)
        requestMacro.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestMacro)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return}
                guard let result = results.first else {return}
                result.setValue(macro.name, forKey: "name")
                result.setValue(macro.carbs, forKey: "carbs")
                result.setValue(macro.fats, forKey: "fats")
                result.setValue(macro.proteins, forKey: "proteins")
                result.setValue(macro.expiration, forKey: "expiration")
                try context.save()
                print("update successful")
            }
        }catch{
            print("update unsuccessful")
        }

    }
    
    func saveMacrosToDevice(macro : Macro, completion : (success : Bool) -> Void) {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let newMacro = NSEntityDescription.insertNewObjectForEntityForName("Macro_Meal", inManagedObjectContext: context)
        newMacro.setValue(macro.name, forKey: "name")
        newMacro.setValue(macro.carbs, forKey: "carbs")
        newMacro.setValue(macro.fats, forKey: "fats")
        newMacro.setValue(macro.proteins, forKey: "proteins")
        newMacro.setValue(macro.expiration, forKey: "expiration")
        newMacro.setValue(macro.id, forKey: "id")
        do {
            try context.save()
            completion(success: true)
        } catch {
            print("There was an error saving the macro")
            completion(success: false)
        }
    }
    
    func deleteMacrosFromDevice(meal : Macro){
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestMacro = NSFetchRequest(entityName: "Macro_Meal")
        requestMacro.predicate = NSPredicate(format: "id = %@", meal.id)
        requestMacro.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestMacro)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return}
                guard let result = results.first else {return}
                context.deleteObject(result)
                try context.save()
                print("delete successful")
            }
        }catch{
            print("delete unsuccessful")
        }
    }

    
    func getMyExercises() -> [Entry] {
        
        var exercises = [Entry]()
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            if results.count > 0 {
                guard let results = results as? [NSManagedObject] else {return []}
                for result in results {
                    guard let title = result.valueForKey("name") as? String else {continue}
                    guard let id = result.valueForKey("identifier") as? String else {continue}
                    guard let muscleGroups = result.valueForKey("muscle_group") as? NSData else {continue}
                    let muscleGroup = unarchiveArray(muscleGroups)
                    guard muscleGroup.count > 0 else {continue}
                    guard let mainMuscleGroup = muscleGroup.first else {continue}
                    exercises.append(Entry(exerciseTitle: title, exerciseIdentifer: id, muscle_group: mainMuscleGroup))
                }
            }
        } catch {
            print("There was an error fetching exercises")
        }
        return exercises
    }
    
    func saveExerciseToDevice(name : String, id : String, muscleGroup : [String], image : NSData, exerciseDescription : String, completion : (success : Bool) -> Void) {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let newExercise = NSEntityDescription.insertNewObjectForEntityForName("Exercise", inManagedObjectContext: context)
        let muscleGroup = archiveArray(muscleGroup)
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
    
    func updateLocalObjectIdentifier(currentId : String, newId : String, entityName : String) {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestExercise = NSFetchRequest(entityName: entityName)
        requestExercise.predicate = NSPredicate(format: "identifier = %@", currentId)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(requestExercise)
            if results.count > 0 {
                guard let result = results.first as? NSManagedObject else {return}
                result.setValue(newId, forKey: "identifier")
                if entityName == "Workout" {
                    result.setValue(true, forKey: "publicWorkout")
                } else {
                    // Check if this exercise is in any locally stored workouts
                    guard let muscleGroups = result.valueForKey("muscle_group") as? NSData else {return}
                    updateLocalExerciseIdentifiers(currentId, newID: newId, muscleGroup: muscleGroups)
                    if let updateXercisesDelegate = self.updateXercisesDelegate {
                        updateXercisesDelegate.updateXercises()
                    }
                    updateParseExerciseIdentifiers(currentId, newId: newId)
                }
                do {
                    try context.save()
                } catch _ {
                    print("error")
                }
            }
        } catch {
            print("There was an error updating the local object's id")
        }
    }
    
    func updateLocalExerciseIdentifiers(currentId: String, newID: String, muscleGroup : NSData) {
        //let archivedMuscleGroups = archiveArray(muscleGroup)
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestExercise = NSFetchRequest(entityName: "Workout")
        //requestExercise.predicate = NSPredicate(format: "muscle_group = %@", muscleGroup)
        requestExercise.returnsObjectsAsFaults = false
        do {
            guard let results = try context.executeFetchRequest(requestExercise) as? [NSManagedObject] else {return}
            if results.count > 0 {
                for result in results {
                    guard let ids = result.valueForKey("exercise_ids") as? NSData else {continue}
                    var unarchivedIds = self.unarchiveArray(ids)
                    guard let index = unarchivedIds.indexOf(currentId) else {continue}
                    unarchivedIds[index] = newID
                    result.setValue(archiveArray(unarchivedIds), forKey: "exercise_ids")
                    try context.save()
                }
            }
        } catch {
            print("There was an error updating the local exercise ids")
        }
    }
    
    func updateParseExerciseIdentifiers(prevId : String, newId: String) {
        let query = PFQuery(className: "Workout")
        query.whereKey("exercise_ids", equalTo: prevId)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            guard error == nil else {return}
            guard let objects = objects else {return}
            guard objects.count > 0 else {return}
            for object in objects {
                guard var exerciseIds = object.valueForKey("exercise_ids") as? [String] else {continue}
                guard let index = exerciseIds.indexOf(prevId) else {continue}
                exerciseIds[index] = newId
                object["exercise_ids"] = exerciseIds
                object.saveEventually()
            }
        }
    }
    
    
    func saveWorkoutToDevice(workoutName : String, workoutMuscleGroup : [String], id : String, exerciseIDs : [String], publicWorkout : Bool, completion : (success : Bool) -> Void) {
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let newWorkout = NSEntityDescription.insertNewObjectForEntityForName("Workout", inManagedObjectContext: context)
        let archivedMuscleGroups = archiveArray(workoutMuscleGroup)
        let archivedExerciseIDs = archiveArray(exerciseIDs)
        newWorkout.setValue(workoutName, forKey: "name")
        newWorkout.setValue(id, forKey: "identifier")
        newWorkout.setValue(archivedExerciseIDs, forKey: "exercise_ids")
        newWorkout.setValue(archivedMuscleGroups, forKey: "muscle_group")
        newWorkout.setValue(publicWorkout, forKey: "publicWorkout")
        do {
            try context.save()
            self.queryParseForExercisesFromGroupCode(exerciseIDs, completion: { (success) -> Void in
                if success {
                    completion(success: true)
                } else {
                    completion(success: false)
                }
            })
        } catch {
            completion(success: false)
        }
    }

    func getWorkoutByID(id : String) -> Workout? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryFound = false
        var entryToReturn = Workout(name: "", muscleGroup: [String](), identifier: "", exerciseIds: [""], exerciseNames: nil, publicWorkout: false, workoutCode: nil)
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
                    let muscleGroup : [String] =  unarchiveArray(result.valueForKey("muscle_group")! as! NSData)
                    
                    // Create the workout object to be returned
                    entryToReturn = Workout(name: result.valueForKey("name")! as! String, muscleGroup: muscleGroup, identifier: result.valueForKey("identifier")! as! String, exerciseIds: exercises, exerciseNames : nil, publicWorkout: result.valueForKey("publicWorkout") as! Bool, workoutCode: result.valueForKey("workoutCode") as! String?)
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
        var entryToReturn = Exercise(name: "", muscleGroup: [String](), identifier: "", description: "", image: UIImage())
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
                    let muscleGroup : [String] =  unarchiveArray(result.valueForKey("muscle_group")! as! NSData)
                    // Create the Exercise object to be returned
                    entryToReturn = Exercise(name: result.valueForKey("name")! as! String, muscleGroup: muscleGroup, identifier: result.valueForKey("identifier")! as! String, description: result.valueForKey("exercise_desc")! as! String, image: image)
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

    
    // MARK: - Parse Functions
    
    func saveExerciseToParse(name : String, id : String, muscleGroup : [String], image : NSData, exerciseDescription : String, completion : (success : Bool) -> Void) {
                
        // Parse exercise object
        let exercise = PFObject(className: "Exercise")
        exercise["name"] = name
        exercise["muscle_groups"] = muscleGroup
        exercise["exercise_desc"] = exerciseDescription
        exercise["thumbs_Down_Rate"] = 0
        exercise["thumbs_Up_Rate"] = 0
        let imageFile = PFFile(name: "image.jpeg", data: image)
        exercise["image"] = imageFile
        exercise.saveInBackgroundWithBlock { (success, error) -> Void in
            //guard error == nil else {return}
            if error == nil {
                if success {
                    if let objectId = exercise.objectId {
                        self.updateLocalObjectIdentifier(id, newId: objectId, entityName: "Exercise")
                        completion(success: true)
                    }
                } else {
                    completion(success: false)
                }
            } else {
                completion(success: false)
            }
        }
    }
    
    
    func saveWorkoutToParse(workoutName : String, workoutMuscleGroup : [String], id : String, exerciseIDs : [String], exerciseNames : [String], completion : (success : Bool, identifier: String?) -> Void) {
        
        // Create Parse object to save
        let workout = PFObject(className: "Workout")
        workout["name"] = workoutName
        workout["exercise_ids"] = exerciseIDs
        workout["muscle_groups"] = workoutMuscleGroup
        workout["exercise_names"] = exerciseNames
        workout.saveInBackgroundWithBlock { (success, error) -> Void in
            if error == nil {
                if success {
                    if let objectId = workout.objectId {
                        self.updateLocalObjectIdentifier(id, newId: objectId, entityName: "Workout")
                        completion(success: true, identifier: objectId)
                    }
                } else {
                    completion(success: false, identifier: nil)
                }
            } else {
                completion(success: false, identifier: nil)
            }
        }
    }
    
    func checkParseExerciseAvailablity(ids : [String], completion : (success : Bool) -> Void) {
        var completionSuccess = true
        for exerciseID in ids {
            checkSingleExerciseAvailabilityOnParse(exerciseID, completion: { (success) -> Void in
                if !success {
                    completionSuccess = false
                }
            })
        }
        if completionSuccess {
            completion(success: true)
        } else {
            completion(success: false)
        }
    }
    
    func checkSingleExerciseAvailabilityOnParse(id : String, completion : (success : Bool) -> Void) {
        let query = PFQuery(className: "Exercise")
        query.whereKey("objectId", equalTo: id)
        query.findObjectsInBackgroundWithBlock({ (objects : [PFObject]?, error: NSError?) -> Void in
            guard error == nil else {completion(success: false);return}
            if let objects = objects {
                if objects.count == 0 {
                    // Not in Parse database, add to Parse
                    if let exerciseToAdd : Exercise = self.getExerciseByID(id) {
                        // Got Exercise from Core Data - now add to Parse
                        if let img = UIImageJPEGRepresentation(exerciseToAdd.image, 0.5) {
                            self.saveExerciseToParse(exerciseToAdd.name, id: exerciseToAdd.identifier, muscleGroup: exerciseToAdd.muscleGroup, image: img, exerciseDescription: exerciseToAdd.description, completion: { (success) -> Void in
                                if success {
                                    completion(success: true)
                                } else {
                                    completion(success: false)
                                }
                            })
                        } else {
                            completion(success: true)
                        }
                    }  else {
                        completion(success: true)
                    }
                }  else {
                    completion(success: true)
                }
            }  else {
                completion(success: true)
            }
        })
    }
    
    func queryParseForWorkoutFromGroupCode(code : String, completion : (workoutFromCode : Workout?) -> Void) { //) -> Workout? {
        let query = PFQuery(className: "Workout")
        query.whereKey("objectId", equalTo: code)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            guard error == nil else {completion(workoutFromCode: nil);return}
            guard let objects = objects else {completion(workoutFromCode: nil);return}
            guard objects.count > 0 else {completion(workoutFromCode: nil);return}
            // Successful query - get workout data
            for object in objects {
                // Retrieve workout fields and check that they are not nil
                guard let name = object.valueForKey("name") as? String else {completion(workoutFromCode: nil);return}
                guard let muscleGroup = object.valueForKey("muscle_groups") as? [String] else {completion(workoutFromCode: nil);return}
                guard let identifier = object.valueForKey("objectId") as? String else {completion(workoutFromCode: nil);return}
                guard let exercise_ids = object.valueForKey("exercise_ids") as? [String] else {completion(workoutFromCode: nil);return}
                guard let exercise_names = object.valueForKey("exercise_names") as? [String] else {completion(workoutFromCode: nil);return}
                
                // Return this workout
                let workout = Workout(name: name, muscleGroup: muscleGroup, identifier: identifier, exerciseIds: exercise_ids, exerciseNames: exercise_names, publicWorkout: true, workoutCode: identifier)
                completion(workoutFromCode: workout)
            }
        }
    }

    func queryParseForExercisesFromGroupCode(ids : [String], completion : (success : Bool) -> Void) {
        var failure = false
        var successes = 0
        for id in ids {
            // Check to see if this exercise is already stored on the device
            self.queryForItemByID(id, entityName: "Exercise", completion: { (success) -> Void in
                if success {
                   successes += 1
                    
                    if !failure && successes == ids.count {
                        completion(success: true)
                        return
                    } else if failure {
                        completion(success: false)
                        return
                    }
                } else {
                    // Exercise not stored on device - query for it
                    let query = PFQuery(className: "Exercise")
                    query.whereKey("objectId", equalTo: id)
                    query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                        guard error == nil else {failure = true;return}
                        guard let objects = objects else {failure = true;return}
                        guard let firstObject = objects.first else {failure = true;return}
                        // Get image data and save to device
                        guard let picture = firstObject.valueForKey("image") as? PFFile else {failure = true;return}
                        picture.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                            guard error == nil else {failure = true;return}
                            guard let imageData = imageData else {failure = true;return}
                            guard let name = firstObject.valueForKey("name") as? String else {failure = true;return}
                            guard let identifier = firstObject.valueForKey("objectId") as? String else {failure = true;return}
                            guard let muscleGroup = firstObject.valueForKey("muscle_groups") as? [String] else {failure = true;return}
                            guard let description = firstObject.valueForKey("exercise_desc") as? String else {failure = true;return}
                            self.saveExerciseToDevice(name, id: identifier, muscleGroup: muscleGroup, image: imageData, exerciseDescription: description, completion: { (success) -> Void in
                                if !success {
                                   print("Error saving exercise to device")
                                    failure = true
                                } else {
                                    successes += 1
                                }
                                
                                if !failure && successes == ids.count {
                                    completion(success: true)
                                } else if failure {
                                    completion(success: false)
                                }
                                
                            })
                        })
                        
                    }
                }
            })
        }
    }
    
    func queryForExerciseFromParse(id : String, completion : (exercise : Exercise?) -> Void) {
        let query = PFQuery(className: "Exercise")
        query.whereKey("objectId", equalTo: id)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                if let objects = objects {
                    // Retrieved an exercise
                    if objects.count == 1 {
                        let first = objects.first
                        if let first = first {
                            let imageFile = first.valueForKey("image") as! PFFile
                            imageFile.getDataInBackgroundWithBlock({ (data, error) -> Void in
                                if error == nil {
                                    if let data = data {
                                        let image = UIImage(data: data)
                                        if let image = image {
                                            let exercise = Exercise(name: first.valueForKey("name") as! String, muscleGroup: first.valueForKey("muscle_groups") as! [String], identifier: id, description: first.valueForKey("exercise_desc") as! String, image: image)
                                            completion(exercise: exercise)
                                        } else {
                                            completion(exercise: nil)
                                        }
                                    } else {
                                        completion(exercise: nil)
                                    }
                                } else {
                                    completion(exercise: nil)
                                }
                            })
                        } else {
                            completion(exercise: nil)
                        }
                    } else {
                        completion(exercise: nil)
                    }
                } else {
                    completion(exercise: nil)
                }
            } else {
                completion(exercise: nil)
            }
        }
    }
    
    // MARK: - Cloud Code Functions
    
    func generateExercise(muscleGroup : String, previousIdentifiers : [String]?, completion : (exercise : Exercise?, resetPreviousIdentifiers : Bool) -> Void) {
        // Check if we have cached exercises for this muscle group
        let exercises : [PFObject]? = exercisesForMuscleGroup[muscleGroup]
        if let exercises = exercises {
            getOneExerciseFromResults(exercises, previousIdentifiers: previousIdentifiers, completion: { (exercise, resetPreviousIdentifiers) -> Void in
                if let exercise = exercise {
                    completion(exercise: exercise, resetPreviousIdentifiers: resetPreviousIdentifiers)
                } else {
                    completion(exercise: nil, resetPreviousIdentifiers: false)
                }
            })
        } else {
            // Query Parse for all objects matching this muscle group
            let query = PFQuery(className: "Exercise")
            query.whereKey("muscle_groups", equalTo: muscleGroup)
            query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
                guard error == nil else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
                guard let objects = objects else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
                guard objects.count > 0 else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
                
                // ** HANDLE IF THERE IS ONLY ONE EXERCISE RETURNED **
                
                // Remove previously cached objects and cache this new set of objects
                self.exercisesForMuscleGroup.removeAll()
                self.exercisesForMuscleGroup[muscleGroup] = objects
                
                // Get one exercise from this array of results
                self.getOneExerciseFromResults(objects, previousIdentifiers: previousIdentifiers, completion: { (exercise, resetPreviousIdentifiers) -> Void in
                    if let exercise = exercise {
                        completion(exercise: exercise, resetPreviousIdentifiers: resetPreviousIdentifiers)
                    } else {
                        completion(exercise: nil, resetPreviousIdentifiers: false)
                    }
                })
            }
        }
    }
    
    func isNewExercise(previousIdentifiers : [String], currentIdentifier : String) -> Bool {
        if previousIdentifiers.contains(currentIdentifier) {
            return false
        } else {
            return true
        }
    }
    
    func getOneExerciseFromResults(objects : [PFObject], previousIdentifiers : [String]?, completion : (exercise : Exercise?, resetPreviousIdentifiers : Bool) -> Void) {
        // Bool flag for resetting previous ids
        var resetPreviousIds = false
        
        // create a random number
        var randomNumber = Int(arc4random_uniform(UInt32(objects.count)))
        var object = objects[randomNumber]
        
        if let previousIdentifiers = previousIdentifiers {
            // Passed previous identifiers, check that this ID is not in the passed array if there are sufficiently many exercises
            if objects.count > previousIdentifiers.count {
                var newExercise = false
                while !newExercise {
                    let id = object.valueForKey("objectId") as? String
                    guard let identifier = id else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
                    if !self.isNewExercise(previousIdentifiers, currentIdentifier: identifier) {
                        // Get a new random number and object
                        randomNumber = Int(arc4random_uniform(UInt32(objects.count)))
                        object = objects[randomNumber]
                    } else {
                        newExercise = true
                    }
                }
            } else {
                resetPreviousIds = true
            }
        }
        
        // Try to retrieve the image as a PFFile, then try to get it's URL
        let file = object.valueForKey("image") as? PFFile
        guard let imageFile = file else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
        let fileUrl = imageFile.url
        guard let imageURL = fileUrl else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
        
        // Create an NSURL and get the image asynchronously
        let urlString = NSURL(string: imageURL)
        guard let url = urlString else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
        self.getDataFromUrl(url, completion: { (data, response, error) -> Void in
            // Check that error is nil and the data is not nil
            guard error == nil else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            guard let data = data else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            
            // Create the image with the recieved data and make sure it's not nil
            let imageWithData = UIImage(data: data)
            guard let image = imageWithData else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            
            // Retrieve exercise fields and check that they are not nil
            let name = object.valueForKey("name") as? String
            let muscleGroup = object.valueForKey("muscle_groups") as? [String]
            let identifier = object.valueForKey("objectId") as? String
            let description = object.valueForKey("exercise_desc") as? String
            guard name != nil else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            guard muscleGroup != nil else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            guard identifier != nil else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            guard description != nil else {completion(exercise: nil, resetPreviousIdentifiers: false);return}
            
            // Return this exercise
            let exercise = Exercise(name: name!, muscleGroup: muscleGroup!, identifier: identifier!, description: description!, image: image)
            completion(exercise: exercise, resetPreviousIdentifiers: resetPreviousIds)
        })
    }
    
    func generateWorkout(muscleGroup : String, completion : (workout : Workout?) -> Void) {
        // Check if cached
        
        // Not cached, need to fetch from Parse
        let query = PFQuery(className: "Workout")
        query.whereKey("muscle_groups", equalTo: muscleGroup)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            // Check that error is nil and object is not nil
            guard error == nil else {completion(workout: nil);return}
            guard let objects = objects else {completion(workout: nil);return}
            guard objects.count > 0 else {completion(workout: nil);return}
            
            if objects.count > 1 {
                // Remove previously cached objects and cache this new set of objects
                self.exercisesForMuscleGroup.removeAll()
                self.exercisesForMuscleGroup[muscleGroup] = objects
                
                // Randomly get an individual workout from the returned list of workouts
                self.getOneWorkoutFromResults(objects, oneObject: false, completion: { (workout) -> Void in
                    if let workout = workout {
                        completion(workout: workout)
                    } else {
                        completion(workout: nil)
                    }
                })
            } else {
                // Retrieve object fields and return this result
                self.getOneWorkoutFromResults(objects, oneObject: true, completion: { (workout) -> Void in
                    if let workout = workout {
                        completion(workout: workout)
                    } else {
                        completion(workout: nil)
                    }
                })
            }
        }
    }
    
    func getOneWorkoutFromResults(objects : [PFObject], oneObject : Bool, completion : (workout : Workout?) -> Void) {
        var object : PFObject
        if !oneObject {
            // create a random number
            let randomNumber = Int(arc4random_uniform(UInt32(objects.count)))
            object = objects[randomNumber]
        } else {
            // Only one object, retrieve workout fields and check that they are not nil
            guard let firstWorkout = objects.first else {completion(workout: nil);return}
            object = firstWorkout
        }
        // Retrieve workout fields and check that they are not nil
        guard let name = object.valueForKey("name") as? String else {completion(workout: nil);return}
        guard let muscleGroup = object.valueForKey("muscle_groups") as? [String] else {completion(workout: nil);return}
        guard let identifier = object.valueForKey("objectId") as? String else {completion(workout: nil);return}
        guard let exercise_ids = object.valueForKey("exercise_ids") as? [String] else {completion(workout: nil);return}
        guard let exercise_names = object.valueForKey("exercise_names") as? [String] else {completion(workout: nil);return}
        
        // Return this workout
        let workout = Workout(name: name, muscleGroup: muscleGroup, identifier: identifier, exerciseIds: exercise_ids, exerciseNames: exercise_names, publicWorkout: true, workoutCode: identifier)
        completion(workout: workout)
    }
    
}

extension NSDate {
    var startOfDay: NSDate {
        return NSCalendar.currentCalendar().startOfDayForDate(self)
    }
    
    var endOfDay: NSDate? {
        let components = NSDateComponents()
        components.day = 1
        components.second = -1
        return NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: startOfDay, options: NSCalendarOptions())
    }
    
    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
    
    func addDays(daysToAdd: Int) -> NSDate {
        let secondsInDays: NSTimeInterval = Double(daysToAdd) * 60 * 60 * 24
        let dateWithDaysAdded: NSDate = self.dateByAddingTimeInterval(secondsInDays)
        
        //Return Result
        return dateWithDaysAdded
    }
    
    func addHours(hoursToAdd: Int) -> NSDate {
        let secondsInHours: NSTimeInterval = Double(hoursToAdd) * 60 * 60
        let dateWithHoursAdded: NSDate = self.dateByAddingTimeInterval(secondsInHours)
        
        //Return Result
        return dateWithHoursAdded
    }
}