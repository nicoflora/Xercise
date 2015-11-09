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
    var muscleGroup : String
    var identifier : String
    var exerciseIDs : [String]
    var publicWorkout : Bool
    var workoutCode : String?
    
    init(name : String, muscleGroup : String, identifier : String, exerciseIds : [String], publicWorkout : Bool, workoutCode : String?) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.identifier = identifier
        self.exerciseIDs = exerciseIds
        self.publicWorkout = publicWorkout
        if let code = workoutCode {
            self.workoutCode = code
        }
    }
}