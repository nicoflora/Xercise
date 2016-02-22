//
//  XerciseConstants.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import Foundation

class XerciseConstants {
    
    let infoCategories = ["Heavy Weight","Endurance","Macro Nutrient"]
    
    let macroInfo = "Macronutrients are nutrients that provide calories or energy. Nutrients are substances needed for growth, metabolism, and for other body functions. Since 'macro' means large macronutrients are nutrients needed in large amounts. There are three macronutrients: Carbohydrates, Proteins, Fats"
    
    let enduranceInfo = "Endurance workout or exercises are aimed to build muscular endurance by doing lighter weight with higher repetitions and sets. For example, someone with a max bench press of 225 would aim to bench 150 at 12 repetitions for 8 sets."
    
    let heavyInfo = "Heavy weight workout or exercises are aimed to build up the muscles by doing heavy weight with low repetitions and sets. For example, someone with a max bench press of 225 would aim to bench 200 pounds at 5 repetitions for 3 sets."
    
    let newExerciseTitles = ["Name","Muscle Group","Image","Description","Suggested Reps","Suggested Sets"]
    
    let newExerciseTitlesSubGroup = ["Name","Muscle Group","Muscle Sub-Group","Image","Description","Suggested Reps","Suggested Sets"]
    
    let newExerciseInWorkoutTitles = ["Name","Image","Description","Suggested Reps","Suggested Sets"]
    
    let newWorkoutTitles = ["Name","Muscle Group","Exercises"]

    let newWorkoutTitlesSubGroup = ["Name","Muscle Group","Muscle Sub-Group", "Exercises"]
    
    let displayExerciseTitles = ["Name","Muscle Group","Image","Description", "Share"]
    
    let exerciseDescriptionText = "An exercise description should contain instructions for performing this exercise, including all equipment and movements. Also mention the skill level required for this exercise."
    
    let muscleGroupsArray : [MuscleGroup] = [MuscleGroup(mainGroup : "Abs", muscleSubGroups : ["All", "Obliques", "Upper Abs", "Lower Abs"]), MuscleGroup(mainGroup : "Arms", muscleSubGroups : ["All","Biceps", "Triceps", "Forearms"]), MuscleGroup(mainGroup : "Back", muscleSubGroups : ["All", "Lats", "Middle Back", "Lower Back"]), MuscleGroup(mainGroup : "Chest", muscleSubGroups : ["All", "Upper Chest", "Middle Chest", "Lower Chest"]), MuscleGroup(mainGroup : "Legs", muscleSubGroups : ["All", "Glutes", "Hamstrings", "Quadriceps", "Calves"]), MuscleGroup(mainGroup : "Shoulders", muscleSubGroups : ["All", "Front Deltoids", "Side Deltoids", "Traps"])]
    
    let muscleGroups = ["Abs", "Arms", "Back", "Chest", "Legs", "Shoulders"]
    
}

enum mainMuscleGroup {
    case abs
    case arms
    case back
    case chest
    case legs
    case shoulders
}