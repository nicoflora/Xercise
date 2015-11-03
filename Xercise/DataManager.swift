//
//  DataManager.swift
//  QRCodeGenerator
//
//  Created by Kyle Blazier on 10/14/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import Foundation

class DataManager {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    func storeEntries(arr : [Entry], key : String) {
        
        let archiveKey = NSKeyedArchiver.archivedDataWithRootObject(arr)
        
        defaults.setObject(archiveKey, forKey: key)
        
    }
    
    /*func storeArrOfAcounts(arr : [[Entry]], key : String) {
        
        let archiveKey = NSKeyedArchiver.archivedDataWithRootObject(arr)
        
        defaults.setObject(archiveKey, forKey: key)
        
    }*/
    
    func retrieveEntries(key : String) -> [Entry] {
        
        let storedAccounts = defaults.objectForKey(key) as? NSData
        
        if let storedAccounts = storedAccounts {
            
            let theAccounts = NSKeyedUnarchiver.unarchiveObjectWithData(storedAccounts) as? [Entry]
            
            if let theAccounts = theAccounts {
                
                // Accounts are stored in NSUserDefaults
                if theAccounts.count > 0 {
                    
                    return theAccounts
                    
                }
            }
        }
        return []
    }
    
    /*func retrieveArrOfAccounts(key : String) -> [[Entry]] {
        
        let storedAccounts = defaults.objectForKey(key) as? NSData
        
        if let storedAccounts = storedAccounts {
            
            let theAccounts = NSKeyedUnarchiver.unarchiveObjectWithData(storedAccounts) as? [[Entry]]
            
            if let theAccounts = theAccounts {
                
                // Accounts are stored in NSUserDefaults
                if theAccounts.count > 0 {
                    
                    return theAccounts
                    
                }
            }
        }
        return []
    }*/

}