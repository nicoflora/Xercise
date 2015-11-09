//
//  Exercise.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/7/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import Foundation
import UIKit

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