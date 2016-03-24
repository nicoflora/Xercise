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
    let dataMGR = DataManager.sharedInstance
    var goal : MacroGoal?
    var tapGesture = UITapGestureRecognizer()

    @IBAction func resetMacrosButton(sender: AnyObject) {
        if macroMeals.count > 0 {
            let alert = UIAlertController(title: "Reset Meals?", message: "Are you sure you want to remove all of your entered meals? This cannot be undone.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Reset", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                self.macroMeals.removeAll()
                self.tableView.reloadData()
                self.dataMGR.resetMyMacros()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func addNewMeal(sender: AnyObject) {
        showNewMealPopup(nil, row : nil, goal: false)
    }
    
    func saveMealData(){
        guard let popup = popup else {return}
        var mealName = ""
        if let row = popup.updateRow{
            // Editing a current meal or goal
            if row != -1 {
                guard let name = popup.mealName.text else {textFieldHasError(popup.mealName);return}
                guard name.characters.count > 0 else {textFieldHasError(popup.mealName);return}
                mealName = name
                textFieldDoesNotHaveError(popup.mealName)
            }
        } else {
            guard let name = popup.mealName.text else {textFieldHasError(popup.mealName);return}
            guard name.characters.count > 0 else {textFieldHasError(popup.mealName);return}
            mealName = name
            textFieldDoesNotHaveError(popup.mealName)
        }
        guard let carbs = popup.mealCarbs.text else {textFieldHasError(popup.mealCarbs);return}
        guard let fats = popup.mealFats.text else {textFieldHasError(popup.mealFats);return}
        guard let proteins = popup.mealProteins.text else {textFieldHasError(popup.mealProteins);return}
        
        guard let carbsNum = Int (carbs) else {textFieldHasError(popup.mealCarbs);return}
        textFieldDoesNotHaveError(popup.mealCarbs)
        guard let fatsNum = Int (fats) else {textFieldHasError(popup.mealFats);return}
        textFieldDoesNotHaveError(popup.mealFats)
        guard let proteinsNum = Int (proteins) else {textFieldHasError(popup.mealProteins);return}
        textFieldDoesNotHaveError(popup.mealProteins)
        
        let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil)) as String
        
        let macro = Macro(name: mealName, carbs: carbsNum, fats: fatsNum, proteins: proteinsNum, expiration: NSDate(), id: uuid)
        
        if let row = popup.updateRow{
            // Editing a current meal or goal
            if row == -1 {
                // Macro Goal
                dataMGR.saveMacroGoalToDevice(MacroGoal(carbs: carbsNum, fats: fatsNum, proteins: proteinsNum))
                goal = MacroGoal(carbs: carbsNum, fats: fatsNum, proteins: proteinsNum)
                tableView.reloadData()
            }else{
                //  Meal
                macroMeals[row] = macro
                dataMGR.updateMacrosToDevice(macro)
            }
        }else{
            macroMeals.append(macro)
            dataMGR.saveMacrosToDevice(macro) { (success) -> Void in
                //print("Saved meal")
            }
        }
        tableView.reloadData()
        cancelPopup()
    }
    
    func textFieldHasError(textField : UITextField) {
        textField.shake()
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.redColor().CGColor
    }
    
    func textFieldDoesNotHaveError(textField : UITextField) {
        textField.layer.borderWidth = 0.0
        textField.layer.borderColor = nil
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
                    //print("Error initializing regex")
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
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(_:)))
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
                cell.percentageGoalAchievedView.backgroundColor = UIColor.whiteColor()
                cell.mealName.font = UIFont(name: "Marker Felt", size: 16)
                cell.mealCarbs.font = UIFont(name: "Marker Felt", size: 15)
                cell.mealFats.font = UIFont(name: "Marker Felt", size: 15)
                cell.mealProteins.font = UIFont(name: "Marker Felt", size: 15)
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
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                //cell.backgroundColor = UIColor(hexString: "#D3D3D3")
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
                cell.percentageGoalAchievedView.backgroundColor = UIColor(hexString: "#D3D3D3")
                cell.percentageGoalAchievedViewConstraint.constant = 0
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("macroMeal", forIndexPath: indexPath) as! MacrosTableViewCell
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                // Fill up cell for goal completion
                cell.percentageGoalAchievedView.backgroundColor = UIColor.whiteColor()
                var totalCount = 0
                if macroMeals.count > 0 {
                    for meal in macroMeals {
                        totalCount += meal.carbs
                        totalCount += meal.fats
                        totalCount += meal.proteins
                    }
                }
                
                cell.mealName.font = UIFont(name: "Marker Felt", size: 20)
                cell.mealName.text = "Goal"
                if let goal = goal {
                    cell.mealCarbs.text = "\(goal.carbs)g"
                    cell.mealFats.text = "\(goal.fats)g"
                    cell.mealProteins.text = "\(goal.proteins)g"
                    
                    // Fill up cell according to the percentage complete the goal is
                    let goalCount = goal.carbs + goal.fats + goal.proteins
                    if totalCount > 0 && goalCount > 0 {
                        let percentageComplete = Double(totalCount) / Double(goalCount)
                        UIView.animateWithDuration(0.3, animations: {
                            //cell.percentageGoalAchievedView.frame = CGRectMake(0,0,cell.bounds.width * CGFloat(percentageComplete),cell.bounds.height)
                            if percentageComplete > 1 {
                                cell.percentageGoalAchievedViewConstraint.constant = 0
                            } else {
                                cell.percentageGoalAchievedViewConstraint.constant = cell.bounds.width - (cell.bounds.width * CGFloat(percentageComplete))
                            }
                            cell.percentageGoalAchievedView.backgroundColor = UIColor.greenColor()
                        })
                    }
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
            if indexPath.row == 0 {
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
            self.tableView.userInteractionEnabled = false
            self.dataMGR.deleteMacrosFromDevice(self.macroMeals[indexPath.row])
            self.macroMeals.removeAtIndex(indexPath.row)
            tableView.reloadData()
            self.tableView.userInteractionEnabled = true
        }
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (Action, indexPath) -> Void in
            self.tableView.userInteractionEnabled = false
            if indexPath.section == 2 && indexPath.row == 1{
                self.showNewMealPopup(nil, row : nil, goal : true)
            } else {
                self.showNewMealPopup(self.macroMeals[indexPath.row], row: indexPath.row, goal : false)

            }
            self.tableView.userInteractionEnabled = true
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
        // If a popup is already being displayed, don't display another one
        guard popup == nil else {return}
    
        if let popup = (NSBundle.mainBundle().loadNibNamed("AddMacroPopupView", owner: UIViewMacro(), options: nil).first as? UIViewMacro){
            self.popup = popup
            popup.frame = CGRectMake((self.view.bounds.width-300)/2, -400, 300, 225) //CGRectMake((self.view.bounds.width-300)/2, 25, 300, 225)
            popup.mealName.delegate = self
            popup.mealCarbs.delegate = self
            popup.mealFats.delegate = self
            popup.mealProteins.delegate = self
            popup.cancelMealButton.layer.borderWidth = 1
            popup.cancelMealButton.layer.borderColor = UIColor(hexString: "#0f3878").CGColor
            popup.saveMealButton.addTarget(self, action: #selector(MacrosTableViewController.saveMealData), forControlEvents: UIControlEvents.TouchUpInside)
            popup.cancelMealButton.addTarget(self, action: #selector(MacrosTableViewController.cancelPopup), forControlEvents: UIControlEvents.TouchUpInside)
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
            } else if goal {
                popup.popUpTitle.text = "Edit Goal"
                popup.mealName.hidden = true
                popup.mealName.enabled = false
                popup.mealNameLabel.hidden = true
                popup.cancelMealButton.setTitle("Cancel", forState: UIControlState.Normal)
                popup.saveMealButton.setTitle("Save", forState: UIControlState.Normal)
                popup.updateRow = -1
                popup.mealNameHeight.constant = 0
                popup.mealNameTextBoxHeight.constant = 0
                popup.frame = CGRectMake((self.view.bounds.width-300)/2, -400, 300, 200) //CGRectMake((self.view.bounds.width-300)/2, 25, 300, 200)
                if let setGoal = self.goal {
                    popup.mealCarbs.text = String(setGoal.carbs)
                    popup.mealFats.text = String(setGoal.fats)
                    popup.mealProteins.text = String(setGoal.proteins)
                }
            }
            // Add the popup to the view and add a tapGestureRecognizer to cancel the popup
            self.view.addSubview(popup)
            self.view.addGestureRecognizer(tapGesture)
            
            // Animate popup in
            UIView.animateWithDuration(0.3, animations: {
                popup.frame = CGRectMake((self.view.bounds.width-300)/2, 25, popup.bounds.width, popup.bounds.height)
            }) { (completed) in
                self.tableView.setEditing(false, animated: true)
            }
        }
    }

    func cancelPopup(){
        guard let popup = popup else {return}
        // Animate popup out
        UIView.animateWithDuration(0.3, animations: {
            popup.frame = CGRectMake((self.view.bounds.width-300)/2, -400, popup.bounds.width, popup.bounds.height)

            }) { (completed) in
                popup.removeFromSuperview()
                self.popup = nil
                self.view.removeGestureRecognizer(self.tapGesture)
        }
    }
    
    func handleTapGesture(gesture : UITapGestureRecognizer) {
        let touchLocation = gesture.locationInView(self.view)
        guard let popup = popup else {return}
        if !popup.frame.contains(touchLocation) {
            // Touches outside of the popup - cancel it
            cancelPopup()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let popup = popup else {return true}
        
        if popup.mealName.editing{
            popup.mealName.resignFirstResponder()
            popup.mealCarbs.becomeFirstResponder()
        }
        
        return true
    }
}
