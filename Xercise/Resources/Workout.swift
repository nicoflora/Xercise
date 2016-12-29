//
//  Workout.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/7/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import Foundation

class Workout {
    var name : String
    var muscleGroup : [String]
    var identifier : String
    var exerciseIDs : [String]
    var exerciseNames : [String]?
    var publicWorkout : Bool
    var workoutCode : String?
    
    init(name : String, muscleGroup : [String], identifier : String, exerciseIds : [String], exerciseNames : [String]?, publicWorkout : Bool, workoutCode : String?) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.identifier = identifier
        self.exerciseIDs = exerciseIds
        if let names = exerciseNames {
            self.exerciseNames = names
        }
        self.publicWorkout = publicWorkout
        if let code = workoutCode {
            self.workoutCode = code
        }
    }
}