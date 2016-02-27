//
//  MacrosTableViewController.swift
//  Xercise
//
//  Created by Nico Flora on 2/23/16.
//  Copyright © 2016 Kyle Blazier. All rights reserved.
//

import UIKit

class MacrosTableViewController: UITableViewController, UITextFieldDelegate {
    
    var popup : UIViewMacro?
    var macroMeals = [Macro]()
    let dataMGR = DataManager()

    @IBAction func addNewMeal(sender: AnyObject) {
        if let popup = (NSBundle.mainBundle().loadNibNamed("AddMacroPopupView", owner: UIViewMacro(), options: nil).first as? UIViewMacro){
            self.popup = popup
            popup.frame = CGRectMake((self.view.bounds.width-300)/2, 25, 300, 225)
            popup.mealCarbs.delegate = self
            popup.mealFats.delegate = self
            popup.mealProteins.delegate = self
            popup.saveMealButton.addTarget(self, action: Selector("saveMealData"), forControlEvents: UIControlEvents.TouchUpInside)
            popup.layer.borderWidth = 3.0
            popup.layer.borderColor =  UIColor(hexString: "#0f3878").CGColor
            popup.layer.cornerRadius = 10
           // popup.saveMealButton.layer.cornerRadius = 10
        
            self.view.addSubview(popup)
        }
    }
    
    func saveMealData(){
        guard let popup = popup else {return}
        guard let name = popup.mealName.text else {return}
        guard let carbs = popup.mealCarbs.text else {return}
        guard let fats = popup.mealFats.text else {return}
        guard let proteins = popup.mealProteins.text else {return}
        
        guard let carbsNum = Int (carbs) else {return}
        guard let fatsNum = Int (fats) else {return}
        guard let proteinsNum = Int (proteins) else {return}
        
        let macro = Macro(name: name, carbs: carbsNum, fats: fatsNum, proteins: proteinsNum, expiration: NSDate())
        
        macroMeals.append(macro)
        
        tableView.reloadData()
        
        dataMGR.saveMacrosToDevice(macro) { (success) -> Void in
            print("Saved meal")
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if string != ""{
            do {
                let regex = try NSRegularExpression(pattern: ".*[^0-9].*", options: NSRegularExpressionOptions.CaseInsensitive)
                if regex.firstMatchInString(string, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, string.characters.count)) != nil {
                    return false
                }
                if textField.text?.characters.count < 3{
                    return true
                }else{
                    return false
                }
            } catch {
                print("Error initializing regex")
                return false
            }
        }
        return true
    }
    
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let myMacros = dataMGR.getMyMacros(){
            macroMeals = myMacros
            tableView.reloadData()
        }
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return macroMeals.count+3
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 25
        }else{
            return 50
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("macroHeader", forIndexPath: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        }else if indexPath.row == macroMeals.count+1{
            let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.backgroundColor = UIColor.greenColor()
            cell.mealName.text = "Total"
            cell.mealName.font = UIFont.systemFontOfSize(15)
            cell.mealCarbs.text = "23g"
            cell.mealFats.text = "18g"
            cell.mealProteins.text = "7g"
            return cell
        }else if indexPath.row == macroMeals.count+2{
            let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.backgroundColor = UIColor.purpleColor()
            cell.mealName.text = "Goal"
            cell.mealName.font = UIFont.systemFontOfSize(15)
            cell.mealCarbs.text = "23g"
            cell.mealFats.text = "18g"
            cell.mealProteins.text = "7g"
            return cell
        }else {
            //if indexPath.row < macroMeals.count{
                let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.mealName.text = macroMeals[indexPath.row-1].name
                cell.mealCarbs.text =  "\(macroMeals[indexPath.row-1].carbs)g"
                cell.mealFats.text = "\(macroMeals[indexPath.row-1].fats)g"
                cell.mealProteins.text = "\(macroMeals[indexPath.row-1].proteins)g"
                return cell
           // }
        }
        return UITableViewCell()
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
