//
//  ExercisesByMuscleGroup.swift
//  Xercise
//
//  Created by Kyle Blazier on 2/17/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import Foundation

class ExercisesByMuscleGroup {
    var muscleGroup : String
    var exercises : [Entry]
    
    init(muscleGroup : String, exercises : [Entry]) {
        self.muscleGroup = muscleGroup
        self.exercises = exercises
    }
}