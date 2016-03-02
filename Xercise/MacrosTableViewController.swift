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
    var goal : MacroGoal?

    @IBAction func resetMacrosButton(sender: AnyObject) {
        macroMeals.removeAll()
        tableView.reloadData()
        dataMGR.resetMyMacros()
    }
    
    
    @IBAction func addNewMeal(sender: AnyObject) {
        showNewMealPopup(nil, row : nil, goal: false)
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
        
        let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil)) as String
        
        let macro = Macro(name: name, carbs: carbsNum, fats: fatsNum, proteins: proteinsNum, expiration: NSDate(), id: uuid)
        
        if let row = popup.updateRow{
            if row == -1 {
                dataMGR.saveMacroGoalToDevice(MacroGoal(carbs: carbsNum, fats: fatsNum, proteins: proteinsNum))
                goal = MacroGoal(carbs: carbsNum, fats: fatsNum, proteins: proteinsNum)
                tableView.reloadData()
            }else{
                macroMeals[row] = macro
                dataMGR.updateMacrosToDevice(macro)
            }
        }else{
            macroMeals.append(macro)
            dataMGR.saveMacrosToDevice(macro) { (success) -> Void in
                print("Saved meal")
            }
        }
        tableView.reloadData()
        popup.removeFromSuperview()
        
        
        
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == popup?.mealName{
            return true
        }else{
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
        }
        return true
    }
    
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let myMacros = dataMGR.getMyMacros(){
            macroMeals = myMacros
            tableView.reloadData()
        }
        
        if let goal = dataMGR.getMyGoal(){
            self.goal = goal
            tableView.reloadData()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section
        {
        case 0:
            return 1
        case 1:
            if macroMeals.count>0{
                return macroMeals.count
            }
            else{
                return 1
            }
        case 2:
            return 2
        default:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section{
        case 0:
            return 25
        default:
            return 50
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        switch indexPath.section{
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("macroHeader", forIndexPath: indexPath)
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 1:
            if macroMeals.count > 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.backgroundColor = UIColor.whiteColor()
                cell.mealName.text = macroMeals[indexPath.row].name
                cell.mealCarbs.text =  "\(macroMeals[indexPath.row].carbs)g"
                cell.mealFats.text = "\(macroMeals[indexPath.row].fats)g"
                cell.mealProteins.text = "\(macroMeals[indexPath.row].proteins)g"
                return cell
            }else{
                let cell = UITableViewCell()
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.textLabel?.text = "Click + To Add New Meals!"
                cell.textLabel?.textAlignment = NSTextAlignment.Center
                cell.textLabel?.font = UIFont(name: "Marker Felt", size: 18)
                return cell
            }
        case 2:
            if indexPath.row == 0
            {
                let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.backgroundColor = UIColor(hexString: "#D3D3D3")
                cell.mealName.font = UIFont(name: "Marker Felt", size: 20)
                cell.mealName.text = "Total"
                if macroMeals.count > 0 {
                    var carbs = 0
                    var fats = 0
                    var proteins = 0
                    for meal in macroMeals {
                        carbs += meal.carbs
                        fats += meal.fats
                        proteins += meal.proteins
                    }
                    
                    cell.mealCarbs.text = "\(carbs)g"
                    cell.mealFats.text = "\(fats)g"
                    cell.mealProteins.text = "\(proteins)g"
                    
                }else{
                    cell.mealCarbs.text = "0g"
                    cell.mealFats.text = "0g"
                    cell.mealProteins.text = "0g"
                }
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.backgroundColor = UIColor.greenColor()
                
                cell.mealName.font = UIFont(name: "Marker Felt", size: 20)
                cell.mealName.text = "Goal"
                if let goal = goal {
                    cell.mealCarbs.text = "\(goal.carbs)g"
                    cell.mealFats.text = "\(goal.fats)g"
                    cell.mealProteins.text = "\(goal.proteins)g"
                }else {
                    cell.mealCarbs.text = "0g"
                    cell.mealFats.text = "0g"
                    cell.mealProteins.text = "0g"
                }
                
                return cell
            }
        default:
            return UITableViewCell()

        }
    }




    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch indexPath.section{
        case 0:
            return false
        case 1:
            if macroMeals.count > 0 {
                return true
            }else{
                return false
            }
            
        case 2:
            if indexPath.row == 0{
                return false
            }else{
                return true
            }
        default:
            return false
        }
        
    }
    

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete") { (Action, indexPath) -> Void in
            self.dataMGR.deleteMacrosFromDevice(self.macroMeals[indexPath.row])
            self.macroMeals.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (Action, indexPath) -> Void in
            
            if indexPath.section == 2 && indexPath.row == 1{
                self.showNewMealPopup(nil, row : nil, goal : true)
            }else {
                self.showNewMealPopup(self.macroMeals[indexPath.row], row: indexPath.row, goal : false)

            }
        }
        editAction.backgroundColor = UIColor(hexString: "#007aff")
        if indexPath.section == 1
        {
            return [deleteAction, editAction]
        }else{
            return [editAction]
        }
    }
    
    func showNewMealPopup(meal : Macro?, row : Int?, goal : Bool){
        tableView.setEditing(false, animated: true)
    
        if let popup = (NSBundle.mainBundle().loadNibNamed("AddMacroPopupView", owner: UIViewMacro(), options: nil).first as? UIViewMacro){
            self.popup = popup
            popup.frame = CGRectMake((self.view.bounds.width-300)/2, 25, 300, 225)
            popup.mealName.delegate = self
            popup.mealCarbs.delegate = self
            popup.mealFats.delegate = self
            popup.mealProteins.delegate = self
            popup.cancelMealButton.layer.borderWidth = 1
            popup.cancelMealButton.layer.borderColor = UIColor(hexString: "#0f3878").CGColor
            popup.saveMealButton.addTarget(self, action: Selector("saveMealData"), forControlEvents: UIControlEvents.TouchUpInside)
            popup.cancelMealButton.addTarget(self, action: Selector("cancelPopup"), forControlEvents: UIControlEvents.TouchUpInside)
            popup.layer.borderWidth = 3.0
            popup.layer.borderColor =  UIColor(hexString: "#0f3878").CGColor
            popup.layer.cornerRadius = 10
            if let meal = meal{
                popup.popUpTitle.text = "Update Meal"
                popup.mealName.text = meal.name
                popup.mealCarbs.text = String(meal.carbs)
                popup.mealFats.text = String(meal.fats)
                popup.mealProteins.text = String(meal.proteins)
                popup.updateRow = row
            }else if goal {
                popup.popUpTitle.text = "Edit Goal"
                popup.mealName.hidden = true
                popup.mealName.enabled = false
                popup.mealNameLabel.hidden = true
                popup.cancelMealButton.setTitle("Cancel", forState: UIControlState.Normal)
                popup.saveMealButton.setTitle("Save", forState: UIControlState.Normal)
                popup.updateRow = -1
                popup.mealNameHeight.constant = 0
                popup.mealNameTextBoxHeight.constant = 0
                popup.frame = CGRectMake((self.view.bounds.width-300)/2, 25, 300, 200)
                if let setGoal = self.goal {
                    popup.mealCarbs.text = String(setGoal.carbs)
                    popup.mealFats.text = String(setGoal.fats)
                    popup.mealProteins.text = String(setGoal.proteins)
                }
                
            }
            self.view.addSubview(popup)
        }
    }

    func cancelPopup(){
        guard let popup = popup else {return}
        popup.removeFromSuperview()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let popup = popup else {return true}
        
        if popup.mealName.editing{
            popup.mealName.resignFirstResponder()
            popup.mealCarbs.becomeFirstResponder()
        }
        
        return true
    }
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
