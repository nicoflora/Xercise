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
    
    init (exerciseTitle : String, exerciseIdentifer : String) {
        self.title = exerciseTitle
        self.identifier = exerciseIdentifer
    }
    
    func encodeWithCoder(coder: NSCoder){
        coder.encodeObject(self.title, forKey: "title")
        coder.encodeObject(self.identifier, forKey: "identifier")
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.title = (aDecoder.decodeObjectForKey("title") as? String)!
        self.identifier = (aDecoder.decodeObjectForKey("identifier") as? String)!
        
        super.init()
    }
    
}

/*class Entry {
    var title : String
    var identifier : String
    
    init(exerciseTitle : String, exerciseIdentifer: String){
        self.title = exerciseTitle
        self.identifier = exerciseIdentifer
    }
}*/