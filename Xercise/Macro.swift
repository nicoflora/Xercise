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
    var id : String
    
    init(name : String, carbs : Int, fats : Int, proteins: Int, expiration : NSDate, id : String){
        self.name = name
        self.carbs = carbs
        self.fats = fats
        self.proteins = proteins
        self.expiration = expiration
        self.id = id
    }
    
    
    
    
}