//
//  Account.swift
//  URcode
//
//  Created by Kyle Blazier on 10/16/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import Foundation

class Entry: NSObject, NSCoding {
    
    var title : String
    var identifier : String
    var muscle_group : String
    
    init (exerciseTitle : String, exerciseIdentifer : String, muscle_group : String) {
        self.title = exerciseTitle
        self.identifier = exerciseIdentifer
        self.muscle_group = muscle_group
    }
    
    func encodeWithCoder(coder: NSCoder){
        coder.encodeObject(self.title, forKey: "title")
        coder.encodeObject(self.identifier, forKey: "identifier")
        coder.encodeObject(self.muscle_group, forKey: "muscle_group")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.title = (aDecoder.decodeObjectForKey("title") as? String)!
        self.identifier = (aDecoder.decodeObjectForKey("identifier") as? String)!
        self.muscle_group = (aDecoder.decodeObjectForKey("muscle_group") as? String)!
        super.init()
    }
}