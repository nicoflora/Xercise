//
//  MuscleSubGroups.swift
//  Xercise
//
//  Created by Kyle Blazier on 2/16/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import Foundation

class MuscleGroup {
    var mainGroup = ""
    var subGroups = [String]()
    
    init(mainGroup : String, muscleSubGroups : [String]) {
        self.mainGroup = mainGroup
        self.subGroups = muscleSubGroups
    }
}