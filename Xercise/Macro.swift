//
//  Macro.swift
//  Xercise
//
//  Created by Nico Flora on 2/27/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import Foundation

class Macro{
    
    var name : String
    var carbs : Int
    var fats : Int
    var proteins : Int
    var expiration : NSDate
    
    init(name : String, carbs : Int, fats : Int, proteins: Int, expiration : NSDate){
        self.name = name
        self.carbs = carbs
        self.fats = fats
        self.proteins = proteins
        self.expiration = expiration
    }
    
    
    
    
}