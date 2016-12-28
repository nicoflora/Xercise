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
import Firebase

class DataManager {
    
    static let sharedInstance = DataManager()
    
    let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let defaults = NSUserDefaults.standardUserDefaults()
    
    var updateXercisesDelegate : XercisesUpdatedDelegate?
    
    // Arrays to cache Parse query results
    var exercisesForMuscleGroup = [String : [PFObject]]()
    var exercisesInWorkoutsMatchingMuscleGroup = [String : [PFObject]]()
    
    var exercisesForMuscleGroupFirebase = [String : [String]]()
    var exercisesInWorkoutsMatchingMuscleGroupFirebase = [String : [String]]()

    
    
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
        //print("Started downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else {
                    //print(error?.localizedDescription)
                    completion(image: nil)
                    return
                }
                //print("Finished downloading \"\(url.URLByDeletingPathExtension!.lastPathComponent!)\".")
                guard let image = UIImage(data: data) else {
                    completion(image: nil)
                    return
                }
                completion(image: image)
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
                //print("There was an error fetching the entry by ID")
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
            //print("There was an error fetching the workouts")
        }
        return workouts
    }
    
    func resetMyMacros(){
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
            //print("Error resetting macros")
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
            //print("There was an error fetching exercises")
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
                //print("delete successful")
            }
        }catch{
            //print("delete unsuccessful")
        }

        let newMacro = NSEntityDescription.insertNewObjectForEntityForName("Macro_Goal", inManagedObjectContext: context)
        newMacro.setValue(goal.carbs, forKey: "carbs")
        newMacro.setValue(goal.fats, forKey: "fats")
        newMacro.setValue(goal.proteins, forKey: "proteins")
        
        do {
            try context.save()
            //print("save successful")
        } catch {
            //print("There was an error saving the goal")
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
            //print("There was an error fetching goal")
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
                //print("update successful")
            }
        }catch{
           // print("update unsuccessful")
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
            //print("There was an error saving the macro")
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
                //print("delete successful")
            }
        }catch{
            //print("delete unsuccessful")
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
            //print("There was an error fetching exercises")
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
            //print("There was an error saving the exercise")
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
                    //print("error")
                }
            }
        } catch {
            //print("There was an error updating the local object's id")
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
            //print("There was an error updating the local exercise ids")
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
    
    
    func saveWorkoutToDevice(creatingWorkout : Bool, workoutName : String, workoutMuscleGroup : [String], id : String, exerciseIDs : [String], publicWorkout : Bool, completion : (success : Bool) -> Void) {
        
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
            if !creatingWorkout {
                self.queryParseForExercisesFromGroupCode(exerciseIDs, completion: { (success) -> Void in
                    if success {
                        completion(success: true)
                    } else {
                        completion(success: false)
                    }
                })
            } else {
                completion(success: true)
            }
        } catch {
            completion(success: false)
        }
    }

    func getWorkoutByID(id : String) -> Workout? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryToReturn = Workout(name: "", muscleGroup: [String](), identifier: "", exerciseIds: [""], exerciseNames: nil, publicWorkout: false, workoutCode: nil)
        let requestWorkout = NSFetchRequest(entityName: "Workout")
        requestWorkout.predicate = NSPredicate(format: "identifier = %@", id)
        requestWorkout.returnsObjectsAsFaults = false
        do {
            let fetchedResults = try context.executeFetchRequest(requestWorkout)
            guard let results = fetchedResults as? [NSManagedObject] else {return nil}
            guard let result = results.first else {return nil}
            
            // Get all values and check that they are not nil
            guard let exercise_ids = result.valueForKey("exercise_ids") as? NSData else {return nil}
            guard let muscle_group = result.valueForKey("muscle_group") as? NSData else {return nil}
            guard let exercises : [String] =  unarchiveArray(exercise_ids) else {return nil}
            guard let muscleGroup : [String] =  unarchiveArray(muscle_group) else {return nil}
            guard let name = result.valueForKey("name") as? String else {return nil}
            guard let identifier = result.valueForKey("identifier") as? String else {return nil}
            guard let publicWorkout = result.valueForKey("publicWorkout") as? Bool else {return nil}
            guard let workoutCode = result.valueForKey("workoutCode") as? String? else {return nil}
            
            // Create the workout object to be returned
            entryToReturn = Workout(name: name, muscleGroup: muscleGroup, identifier: identifier, exerciseIds: exercises, exerciseNames : nil, publicWorkout: publicWorkout, workoutCode: workoutCode)
            //}
            return entryToReturn
        } catch {
            //print("There was an error fetching the workout by ID")
            return nil
        }
    }
    
    func getExerciseByID(id : String) -> Exercise? {
        
        let context : NSManagedObjectContext = appDel.managedObjectContext
        var entryToReturn = Exercise(name: "", muscleGroup: [String](), identifier: "", description: "", image: UIImage())
        let requestExercise = NSFetchRequest(entityName: "Exercise")
        requestExercise.predicate = NSPredicate(format: "identifier = %@", id)
        requestExercise.returnsObjectsAsFaults = false
        do {
            let fetchedResults = try context.executeFetchRequest(requestExercise)
            guard let results = fetchedResults as? [NSManagedObject] else {return nil}
            guard let result = results.first else {return nil}
            
            // Get all values and check that they are not nil
            guard let imageData = result.valueForKey("image") as? NSData else {return nil}
            guard let muscle_group = result.valueForKey("muscle_group") as? NSData else {return nil}
            guard let image : UIImage = UIImage(data: imageData) else {return nil}
            guard let muscleGroup : [String] =  unarchiveArray(muscle_group) else {return nil}
            guard let name = result.valueForKey("name") as? String else {return nil}
            guard let identifier = result.valueForKey("identifier") as? String else {return nil}
            guard let exercise_desc = result.valueForKey("exercise_desc") as? String else {return nil}

            // Create the Exercise object to be returned
            entryToReturn = Exercise(name: name, muscleGroup: muscleGroup, identifier: identifier, description: exercise_desc, image: image)
            return entryToReturn
        } catch {
            //print("There was an error fetching the workout by ID")
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
            //print("There was an error fetching the \(entityName) by ID")
            completion(success: false)
        }
    }

    func addGroupCodeByID(id : String, code : String, completion : (success : Bool) -> Void) {
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let requestWorkout = NSFetchRequest(entityName: "Workout")
        requestWorkout.predicate = NSPredicate(format: "identifier = %@", id)
        requestWorkout.returnsObjectsAsFaults = false
        do {
            let fetchedResults = try context.executeFetchRequest(requestWorkout)
            guard let results = fetchedResults as? [NSManagedObject] else {completion(success: false);return}
            guard results.count > 0 else {completion(success: false);return}
            for result in results {
                result.setValue(code, forKey: "workoutCode")
                result.setValue(true, forKey: "publicWorkout")
                do {
                    try context.save()
                    completion(success: true)
                } catch {
                    completion(success: false)
                }
            }
        } catch {
            //print("There was an error adding the group code by ID")
            completion(success: false)
        }
    }
    
    func deleteItemByID(id : String, entityName : String, completion : (success : Bool) -> Void) {
        let context : NSManagedObjectContext = appDel.managedObjectContext
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = NSPredicate(format: "identifier = %@", id)
        request.returnsObjectsAsFaults = false
        do {
            let fetchedResults = try context.executeFetchRequest(request)
            guard let results = fetchedResults as? [NSManagedObject] else {completion(success: false);return}
            guard results.count > 0 else {completion(success: false);return}
            for result in results {
                // Delete from Core Data
                context.deleteObject(result)
                do {
                    try context.save()
                    completion(success: true)
                } catch {
                    //print("There was an error saving after delection of a \(entityName)")
                    completion(success: false)
                }
                
            }
        } catch {
            //print("There was an error deleting the \(entityName) by ID")
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
        exercise["approved"] = false
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
        workout["approved"] = false
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
    
    func checkSingleExerciseAvailabilityOnFirebase(id : String, completion : (success : Bool) -> Void) {
        
        getExerciseFromDB(withID: id) { (exercise) in
            
            if let _ = exercise {
                // Exercise exists on Firebase
                completion(success: true)
            } else {
                // Doesn't exist - add it
            }
            
        }
        
    }
    
    func checkSingleExerciseAvailabilityOnParse(id : String, completion : (success : Bool) -> Void) {
        let query = PFQuery(className: "Exercise")
        query.whereKey("objectId", equalTo: id)
        query.findObjectsInBackgroundWithBlock({ (objects : [PFObject]?, error: NSError?) -> Void in
            guard error == nil else {completion(success: false);return}
            guard let objects = objects else {completion(success: true);return}
            guard objects.count == 0 else {completion(success: true);return}
            // Not in Parse database, add to Parse
            if let exerciseToAdd : Exercise = self.getExerciseByID(id) {
                // Got Exercise from Core Data - now add to Parse
                if let img = UIImageJPEGRepresentation(exerciseToAdd.image, 0.7) {
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
        })
    }

    func queryParseForExercisesFromGroupCode(ids : [String], completion : (success : Bool) -> Void) {
        var exercisesToFetch = [String]()
        var wasSuccessful = false
        var attempts = 0
        // Check if any exercises are already saved to the device
        for id in ids {
            // Check to see if this exercise is already stored on the device
            self.queryForItemByID(id, entityName: "Exercise", completion: { (success) -> Void in
                if success {
                    attempts += 1
                    wasSuccessful = true
                    
                    if attempts == ids.count {
                        // All exercises were saved to device
                        completion(success: true)
                        return
                    }
                } else {
                    exercisesToFetch.append(id)
                }
            })
        }
        
        // Fetch each exercise from the DB that isnt on the device already
        for ex in exercisesToFetch {
            self.getExerciseFromDB(withID: ex, completion: { (exercise) in
                if let exercise = exercise {
                    // Save exercise
                    guard let imageData = UIImageJPEGRepresentation(exercise.image, 1.0) else {attempts += 1;return}
                    self.saveExerciseToDevice(exercise.name, id: exercise.identifier, muscleGroup: exercise.muscleGroup, image: imageData, exerciseDescription: exercise.description, completion: { (success) in
                        attempts += 1
                        if success {
                            if !wasSuccessful {
                                wasSuccessful = true
                            }
                        }
                        
                        // Check number of attempts
                        if attempts == ids.count {
                            // Attempted to get every exercise - return completion handler
                            completion(success: wasSuccessful)
                            return
                        }
                    })
                } else {
                    attempts += 1
                }
                
                // Check number of attempts
                if attempts == ids.count {
                    // Attempted to get every exercise - return completion handler
                    completion(success: wasSuccessful)
                    return
                }
                
            })
        }
        
    }
    
    // MARK: - Generate exercise or workout functions
    
    func generateExercise(muscleGroup : String, previousIdentifiers : [String]?, completion : (exercise : Exercise?, resetPreviousIdentifiers : Bool) -> Void) {
        // Check if we have cached exercises for this muscle group
        if let exerciseIDs = exercisesForMuscleGroupFirebase[muscleGroup] {
            getOneExerciseFromResults(exerciseIDs, previousIdentifiers: previousIdentifiers, completion: { (exercise, resetPreviousIdentifiers) -> Void in
                if let exercise = exercise {
                    completion(exercise: exercise, resetPreviousIdentifiers: resetPreviousIdentifiers)
                } else {
                    completion(exercise: nil, resetPreviousIdentifiers: false)
                }
            })
        } else {
            
            // Query Firebase for all objects matching this muscle group
            databaseRef().child("muscleGroups/\(muscleGroup)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in

                guard snapshot.exists() else {return}

                guard let exercisesInMuscleGroup = snapshot.value as? [String:AnyObject] else {return}

                let exerciseIDs = Array(exercisesInMuscleGroup.keys)
                
                // Remove previously cached objects and cache this new set of objects
                self.exercisesForMuscleGroup.removeAll()
                self.exercisesForMuscleGroupFirebase[muscleGroup] = exerciseIDs
                
                // Get one exercise from this array of results
                self.getOneExerciseFromResults(exerciseIDs, previousIdentifiers: previousIdentifiers, completion: { (exercise, resetPreviousIdentifiers) -> Void in
                    if let exercise = exercise {
                        completion(exercise: exercise, resetPreviousIdentifiers: resetPreviousIdentifiers)
                    } else {
                        completion(exercise: nil, resetPreviousIdentifiers: false)
                    }
                })
                
            })
        }
    }
    
    func isNewIdentifier(previousIdentifiers : [String], currentIdentifier : String) -> Bool {
        if previousIdentifiers.contains(currentIdentifier) {
            return false
        } else {
            return true
        }
    }
    
    func getOneExerciseFromResults(exerciseIDs : [String], previousIdentifiers : [String]?, completion : (exercise : Exercise?, resetPreviousIdentifiers : Bool) -> Void) {
        // Bool flag for resetting previous ids
        var resetPreviousIds = false
        
        // create a random number
        var randomNumber = Int(arc4random_uniform(UInt32(exerciseIDs.count)))
        var exerciseID = exerciseIDs[randomNumber]
        
        if let previousIdentifiers = previousIdentifiers {
            // Passed previous identifiers, check that this ID is not in the passed array if there are sufficiently many exercises
            if exerciseIDs.count > previousIdentifiers.count {
                var newExercise = false
                while !newExercise {
                    if !self.isNewIdentifier(previousIdentifiers, currentIdentifier: exerciseID) {
                        // Get a new random number and object
                        randomNumber = Int(arc4random_uniform(UInt32(exerciseIDs.count)))
                        exerciseID = exerciseIDs[randomNumber]
                    } else {
                        newExercise = true
                    }
                }
            } else {
                resetPreviousIds = true
            }
        }
        
        self.getExerciseFromDB(withID: exerciseID) { (exercise) in
            if let exercise = exercise {
                completion(exercise: exercise, resetPreviousIdentifiers: resetPreviousIds)
            } else {
                completion(exercise: nil, resetPreviousIdentifiers: resetPreviousIds)
            }
        }
        
    }
    
    
    func getExerciseFromDB(withID exerciseID: String, completion: (exercise: Exercise?) -> Void) {
        
        // Fetch exercise with predetermined ID, then download image, then return Exercise object
        databaseRef().child("exercises/results/\(exerciseID)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            guard snapshot.exists() else {completion(exercise: nil);return}
            
            guard let exerciseDict = snapshot.value as? [String:AnyObject] else {completion(exercise: nil);return}
            
            guard let name = exerciseDict["name"] as? String else {completion(exercise: nil);return}
            
            guard let muscleGroups = exerciseDict["muscle_groups"] as? [String] else {completion(exercise: nil);return}
            
            guard let description = exerciseDict["exercise_desc"] as? String else {completion(exercise: nil);return}
            
            guard let downloadURL = exerciseDict["imageURL"] as? String else {completion(exercise: nil);return}
            
            guard let imgURL = NSURL(string: downloadURL) else {completion(exercise: nil);return}
            
            self.downloadImage(imgURL, completion: { (image) in
                if let image = image {
                    completion(exercise: Exercise(name: name, muscleGroup: muscleGroups, identifier: exerciseID, description: description, image: image))
                } else {
                    completion(exercise: nil)
                }
            })
            
        }) { (error) in
            completion(exercise: nil)
        }
        
    }
    
    func getWorkoutFromDB(withID workoutID: String, completion: (workout: Workout?) -> Void) {
        
        // Fetch exercise with predetermined ID, then download image, then return Exercise object
        databaseRef().child("workouts/results/\(workoutID)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            guard snapshot.exists() else {completion(workout: nil);return}
            
            guard let workoutDict = snapshot.value as? [String:AnyObject] else {completion(workout: nil);return}
            
            guard let name = workoutDict["name"] as? String else {completion(workout: nil);return}
            
            guard let muscleGroups = workoutDict["muscle_groups"] as? [String] else {completion(workout: nil);return}
            
            guard let exerciseNames = workoutDict["exercise_names"] as? [String] else {completion(workout: nil);return}
            
            guard let exerciseIDs = workoutDict["exercise_ids"] as? [String] else {completion(workout: nil);return}
            
            completion(workout: Workout(name: name, muscleGroup: muscleGroups, identifier: workoutID, exerciseIds: exerciseIDs, exerciseNames: exerciseNames, publicWorkout: true, workoutCode: workoutID))
            
        }) { (error) in
            completion(workout: nil)
        }
        
    }


    func generateWorkout(muscleGroup : String, previousIdentifiers : [String]?, completion : (workout : Workout?, resetPreviousIdentifiers : Bool) -> Void) {
        // Check if cached
        if let workoutIDs = exercisesInWorkoutsMatchingMuscleGroupFirebase[muscleGroup] {
            // Randomly get an individual workout from the cached list of workouts
            self.getOneWorkoutFromResults(workoutIDs, previousIdentifiers: previousIdentifiers, oneObject: false, completion: { (workout, resetPreviousIdentifiers) -> Void in
                if let workout = workout {
                    completion(workout: workout, resetPreviousIdentifiers : resetPreviousIdentifiers)
                } else {
                    completion(workout: nil, resetPreviousIdentifiers : false)
                }
            })
        } else {
            
            // Not cached, need to fetch from Firebase
            // Query Firebase for all objects matching this muscle group
            databaseRef().child("workoutMuscleGroups/\(muscleGroup)").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                guard snapshot.exists() else {completion(workout: nil, resetPreviousIdentifiers : false);return}
                
                guard let workoutsInMuscleGroup = snapshot.value as? [String:AnyObject] else {completion(workout: nil, resetPreviousIdentifiers : false);return}
                
                let workoutIDs = Array(workoutsInMuscleGroup.keys)
                
                // Remove previously cached objects and cache this new set of objects
                self.exercisesInWorkoutsMatchingMuscleGroupFirebase.removeAll()
                self.exercisesInWorkoutsMatchingMuscleGroupFirebase[muscleGroup] = workoutIDs
                
                // Randomly get an individual workout from the returned list of workouts
                self.getOneWorkoutFromResults(workoutIDs, previousIdentifiers: previousIdentifiers, oneObject: false, completion: { (workout, resetPreviousIdentifiers) -> Void in
                        completion(workout: workout, resetPreviousIdentifiers: resetPreviousIdentifiers)
                })                
            })
        }
    }
    
    func getOneWorkoutFromResults(workoutIDs : [String], previousIdentifiers : [String]?, oneObject : Bool, completion : (workout : Workout?, resetPreviousIdentifiers : Bool) -> Void) {
        var workoutID : String = ""
        // Bool flag for resetting previous ids
        var resetPreviousIds = false
        
        if workoutIDs.count > 1 {
            // create a random number
            var randomNumber = Int(arc4random_uniform(UInt32(workoutIDs.count)))
            workoutID = workoutIDs[randomNumber]
            
            if let previousIdentifiers = previousIdentifiers {
                // Passed previous identifiers, check that this ID is not in the passed array if there are sufficiently many workouts
                if workoutIDs.count > previousIdentifiers.count {
                    var newWorkout = false
                    while !newWorkout {
                        if !self.isNewIdentifier(previousIdentifiers, currentIdentifier: workoutID) {
                            // Get a new random number and object
                            randomNumber = Int(arc4random_uniform(UInt32(workoutIDs.count)))
                            workoutID = workoutIDs[randomNumber]
                        } else {
                            newWorkout = true
                        }
                    }
                } else {
                    resetPreviousIds = true
                }
            }
        } else {
            // Only one object, retrieve workout fields and check that they are not nil
            guard let firstWorkout = workoutIDs.first else {completion(workout: nil, resetPreviousIdentifiers : resetPreviousIds);return}
            workoutID = firstWorkout
        }
        
        // Fetch workout from Firebase
        self.getWorkoutFromDB(withID: workoutID) { (workout) in
            completion(workout: workout, resetPreviousIdentifiers: resetPreviousIds)
        }
    
    }
    
    
    // MARK: - Firebase functions
    
    var databaseReference: FIRDatabaseReference?
    
    var storageReference: FIRStorageReference?
    
    func databaseRef() -> FIRDatabaseReference {
        if let ref = databaseReference {
            return ref
        }
        
        let ref = FIRDatabase.database().reference()
        databaseReference = ref
        return ref
    }
    
    func storageRef() -> FIRStorageReference {
        if let ref = storageReference {
            return ref
        }
        
        let ref = FIRStorage.storage().reference()
        storageReference = ref
        return ref
    }
    
    func testFirebase() {
        //sortMuscleGroups()
        //uploadPhotos()
    }
    
//    func sortMuscleGroups() {
//        
//        databaseRef().child("exercises/results").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//            
//            guard snapshot.exists() else {return}
//            
//            guard let exercises = snapshot.value as? [String:AnyObject] else {return}
//            
//            let exerciseIDs = Array(exercises.keys)
//            
//            for exID in exerciseIDs {
//                
//                guard let exercise = exercises[exID] as? [String:AnyObject] else {continue}
//                
//                self.storageRef().child("exercises/\(exID)").downloadURLWithCompletion({ (downloadURL, error) in
//                    if let error = error {
//                        print("*** Error retrieving download URL for image with ID: \(exID)")
//                    } else if let downloadURL = downloadURL {
//                        
//                        if let downloadString = downloadURL.absoluteString {
//                            self.databaseRef().child("exercises/results/\(exID)").updateChildValues(["imageURL": downloadString])
//                            print("Successfully updated download URL for image with ID: \(exID) - URL = \(downloadString)")
//                        } else {
//                            print("*** Error retrieving download URL for image with ID: \(exID)")
//                        }
//                        
//                    } else {
//                        print("*** Error retrieving download URL for image with ID: \(exID)")
//                    }
//                })
//            
////                var exName = ""
////                
////                if let name = exercise["name"] as? String {
////                    
////                    exName = name
////                }
////
////                
////                if let muscleGroups = exercise["muscle_groups"] as? [String] {
////                    
////                    for value in muscleGroups {
////                        
////                        self.addValueToUserDetailsObject(value, value: exID, val2: exName)
////                        
////                    }
////                    
////                }
//                
//            }
//            
//            print("\n**** SORTING COMPLETE ****")
//            
//            guard let dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("firebaseDictWorkout") else {return}
//            
//            print(dict)
//            
//            self.setMuscleGroups(dict)
//            
//            }) { (error) in
//                print(error)
//                print("failure")
//        }
//        
//    }
    
//    func setMuscleGroups(muscleGroups: [String:AnyObject]) {
//        
//        databaseRef().child("workoutMuscleGroups").setValue(muscleGroups) //muscleGroups
//        
//    }
    
//    func uploadPhotos() {
//        
//        databaseRef().child("exercises/results").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
//            
//            guard snapshot.exists() else {return}
//            
//            guard let exercises = snapshot.value as? [String:AnyObject] else {return}
//            
//            let exerciseIDs = Array(exercises.keys)
//            
//            for exID in exerciseIDs {
//                
//                guard let exercise = exercises[exID] as? [String:AnyObject] else {continue}
//                
//                if let imageData = exercise["image"] as? [String:AnyObject] {
//                    
//                    if let url = imageData["url"] as? String {
//                        
//                        guard let downloadURL = NSURL(string: url) else {
//                            
//                            print("** Error uploading image for ID: \(exID) **")
//                            return
//                            
//                        }
//                        
//                        self.downloadImage(downloadURL, completion: { (image) in
//                            if let image = image {
//                                self.uploadImageToStorage(exID, image: image)
//                            } else {
//                                print("** Error uploading image for ID: \(exID) **")
//                            }
//                        })
//                        
//                        
//                    }
//                    
//                }
//                
//            }
//            
//            
//        }) { (error) in
//            print(error)
//            print("failure")
//        }
//        
//    }
    
//    func uploadImageToStorage(exerciseID:String, image: UIImage) {
//        
//        if let img = UIImageJPEGRepresentation(image, 1.0) {
//            
//            let metadata = FIRStorageMetadata()
//            metadata.contentType = "image/jpeg"
//            
//            storageRef().child("exercises/\(exerciseID)").putData(img, metadata: metadata, completion: { (metadata, error) in
//                if let error = error {
//                    print("** Error (\(error.localizedDescription)) uploading image for ID: \(exerciseID) **")
//                } else if metadata == nil {
//                    print("** Error uploading image for ID: \(exerciseID) **")
//                } else {
//                    print("Successfully uploaded an image for ID: \(exerciseID)")
//                }
//            })
//            
//        }
//        
//    }

    
    // MARK: - User Detial Obj for setting up firebase
    
//    func getUserDetailsObject() -> [String:AnyObject]? {
//        let dict = NSUserDefaults.standardUserDefaults().dictionaryForKey("firebaseDictWorkout")
//        
//        //print(dict)
//        
//        return dict
//    }
//    
//    func setUserDetailsObject(userDetails: [String:AnyObject]) {
//        NSUserDefaults.standardUserDefaults().setObject(userDetails, forKey: "firebaseDictWorkout")
//        //print(userDetails)
//    }
//    
//    func addValueToUserDetailsObject(key : String, value : String, val2 : String) {
//        
//        print("Adding muscle group: \(key) with exercise ID: \(value) and exercise name \(val2)\n")
//        
//        if var userDetails = getUserDetailsObject() {
//            
//            // Check if key exists
//            var setToDict = [String:String]()
//            if var values = userDetails[key] as? [String:String] {
//                values[value] = val2
//                setToDict = values
//            } else {
//                setToDict[value] = val2
//            }
//            
//            userDetails[key] = setToDict
//            setUserDetailsObject(userDetails)
//        } else {
//            // dictionary doesn't exist - create it now then save
//            var newUserDetails = [String:AnyObject]()
//            
//            var setToDict = [String:String]()
//            setToDict[value] = val2
//            
//            newUserDetails[key] = setToDict
//            setUserDetailsObject(newUserDetails)
//        }
//    }
//    
//    func getValueFromUserDetailsObject(key: String) -> AnyObject? {
//        guard let dict = getUserDetailsObject() else {return nil}
//        return dict[key]
//    }
//    
//    func getBoolFromUserDetailsObject(key: String) -> Bool {
//        guard let dict = getUserDetailsObject() else {return false}
//        guard let value = dict[key] as? Bool else {return false}
//        return value
//    }
//    
//    func removeValueFromUserDetailsObject(key: String) {
//        guard var dict = getUserDetailsObject() else {return}
//        dict.removeValueForKey(key)
//        setUserDetailsObject(dict)
//    }
    
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
