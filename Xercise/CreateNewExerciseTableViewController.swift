//
//  CreateNewExerciseTableViewController.swift
//  Xercise
//
//  Created by Kyle Blazier on 11/1/15.
//  Copyright © 2015 Kyle Blazier. All rights reserved.
//

import UIKit
import CoreData
import Parse

class CreateNewExerciseTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var sectionTitles = [String]()
    var muscleGroups = [String]()
    var exerciseTitle = ""
    var exerciseMuscleGroup = ""
    var image = UIImage(named: "new_exercise_icon")
    var exerciseDescription = ""
    var heavyReps = -1
    var enduranceReps = -1
    var heavySets = -1
    var enduranceSets = -1
    var activityIndicator = UIActivityIndicatorView()
    @IBOutlet var newExerciseTableView: UITableView!
    
    let constants = XerciseConstants()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sectionTitles = constants.newExerciseTitles
        muscleGroups = constants.muscleGroups
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    @IBAction func saveExercise(sender: AnyObject) {
        
        /*print("Title: \(exerciseTitle)")
        print("Muscle Group: \(exerciseMuscleGroup)")
        print("Description: \(exerciseDescription)")
        print("Heavy Reps: \(heavyReps)")
        print("Endurance Reps: \(enduranceReps)")
        print("Heavy Sets: \(heavySets)")
        print("Endurance Sets: \(enduranceSets)")
        
        exerciseDescription += " The suggested number of heavy reps is: \(heavyReps), and the suggested number of endurance reps is: \(enduranceReps).\nThe suggested number of heavy sets is: \(heavySets), and the suggested number of endurance sets is: \(enduranceSets)."
        
        print(exerciseDescription)*/
        
        var dataValidated = false
        
        // Validate Data
        if exerciseTitle.characters.count > 3 {
            if image != UIImage(named: "new_exercise_icon"){
                if exerciseMuscleGroup != "" {
                    if exerciseDescription != constants.exerciseDescriptionText {
                        if heavyReps != -1 && enduranceReps != -1 && heavySets != -1 && enduranceSets != -1 {
                            
                            // All validations passed
                            dataValidated = true
                            
                            // Prompt user for saving the exercise to the community or just on the device
                            let publicActionSheet = UIAlertController(title: nil, message: "Would you like to allow this exercise to be publicly accessible by other members of the community, or keep the exercise private?", preferredStyle: UIAlertControllerStyle.ActionSheet)
                            publicActionSheet.addAction(UIAlertAction(title: "Public", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                // Save the exercise to the device and Parse DB
                                
                                // Save to Parse
                                self.displayActivityIndicator()
                                self.saveToParse()
                                // Save to core data
                                self.saveToDevice()
                            }))
                            publicActionSheet.addAction(UIAlertAction(title: "Private", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                
                                // Save the exercise to the device only
                                self.saveToDevice()
                            }))
                            publicActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                            self.presentViewController(publicActionSheet, animated: true, completion: nil)
                            
                        }
                    }
                }
            }
        }
        
        if dataValidated == false {
            displayAlert("Error!", message: "There was an error in your exercise data. Please review your data and try again.")
        }
        
    }
    
    func saveToParse() {
        
        // Save to Parse
        let exercise = PFObject(className: "Exercise")
        
        exercise["name"] = self.exerciseTitle
        exercise["muscle_group"] = self.exerciseMuscleGroup
        exercise["exercise_desc"] = self.exerciseDescription
        let identifier = Int(arc4random())
        exercise["identifier"] = identifier
        
        if let imageData = UIImageJPEGRepresentation(self.image!, 0.5) {
            let imageFile = PFFile(name: "image.png", data: imageData)
            exercise["image"] = imageFile
            
            //self.displayActivityIndicator()
            
            exercise.saveInBackgroundWithBlock { (success, error) -> Void in
                self.displayActivityIndicator()
                if error == nil {
                    self.displayAlert("Success", message: "Your exercise has been saved!")
                    
                    // Dismiss VC
                    //self.dismissViewControllerAnimated(true, completion: nil)
                    
                } else {
                    self.displayAlert("Error", message: "There was an error saving your exercise, please try again.")
                }
            }
        }
    }
    
    func saveToDevice() {
        
        let appDel : AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context : NSManagedObjectContext = appDel.managedObjectContext

        let img = UIImagePNGRepresentation(self.image!)
        
        let newExercise = NSEntityDescription.insertNewObjectForEntityForName("Exercise", inManagedObjectContext: context)
        newExercise.setValue(self.exerciseTitle, forKey: "name")
        newExercise.setValue(self.exerciseMuscleGroup, forKey: "muscle_group")
        newExercise.setValue(img, forKey: "image")
        newExercise.setValue(self.exerciseDescription, forKey: "exercise_desc")
        newExercise.setValue(Int(arc4random()), forKey: "identifier")
        
        do {
            //self.displayActivityIndicator()
            try context.save()
            //self.displayActivityIndicator()
        } catch {
            //self.displayActivityIndicator()
            print("There was an error posting the data")
        }
        
        // TEST CODE ONLY - Check for exercises
        let request = NSFetchRequest(entityName: "Exercise")
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.executeFetchRequest(request)
            print(results)
            
            /*if results.count > 0 {
            for result in results as! [NSManagedObject] {
            print(result.valueForKey("exercise_desc")!)
            }
            }*/
        } catch {
            print("There was an error fetching")
        }
    }
    
    func displayActivityIndicator() {
        if activityIndicator.isAnimating() {
            activityIndicator.stopAnimating()
            //activityIndicator.removeFromSuperview()
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        } else {
            activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
            activityIndicator.center = self.view.center
            activityIndicator.hidesWhenStopped = true
            activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
            activityIndicator.backgroundColor = UIColor.grayColor()
            view.addSubview(activityIndicator)
            view.bringSubviewToFront(activityIndicator)
            activityIndicator.startAnimating()
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }
    }
    
    func removeActivityIndicator() {
        activityIndicator.stopAnimating()
        //activityIndicator.removeFromSuperview()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGrayColor()
        
        let header = UITableViewHeaderFooterView()
        header.textLabel?.font = UIFont(name: "Marker Felt", size: 16)
        header.textLabel?.textColor = UIColor.blackColor()
    }
    
    /*override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.lightGrayColor() //UIColor(hexString: "#0f3878")
        
        let label = UILabel(frame: CGRectMake(0,0,29,100))
        label.text = sectionTitles[section]
        label.textColor = UIColor(hexString: "#0f3878")
        
        view.addSubview(label)
        
        return view
    }*/

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return muscleGroups.count
        } else {
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0: return 44
        case 1: return 44
        case 2: return 54
        case 3: return 150
        case 4: return 85
        case 5: return 85
        default: return 44
        }

    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("exerciseTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextFieldTextDidChangeNotification, object: nil)
            return cell
        case 1:
            let cell = UITableViewCell()
            cell.textLabel?.text = muscleGroups[indexPath.row]
            if exerciseMuscleGroup == muscleGroups[indexPath.row] {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier("exerciseImage", forIndexPath: indexPath) as! ExerciseImageTableViewCell
            cell.addImageButton.addTarget(self, action: "addImage:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.exerciseImage.image = image
            return cell
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("exerciseDescription", forIndexPath: indexPath) as! ExerciseDescriptionTableViewCell
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveData:", name: UITextViewTextDidChangeNotification, object: nil)
            return cell
        case 4:
            let cell = tableView.dequeueReusableCellWithIdentifier("exerciseReps", forIndexPath: indexPath) as! ExerciseRepsTableViewCell
            cell.heavyStepper.tag = 0
            cell.enduranceStepper.tag = 1
            cell.heavyStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.enduranceStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            return cell
        case 5:
            let cell = tableView.dequeueReusableCellWithIdentifier("exerciseSets", forIndexPath: indexPath) as! ExerciseSetsTableViewCell
            cell.heavyStepper.tag = 2
            cell.enduranceStepper.tag = 3
            cell.heavyStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.enduranceStepper.addTarget(self, action: "stepperValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
            return cell
        default:
            let cell = UITableViewCell()
            cell.textLabel?.text = "There was an error, please try reloading the page."
            return cell
        }
    }
    
    func saveData(notif : NSNotification) {
        
        if let textField = notif.object as? UITextField {
            // Saving title field
            exerciseTitle = textField.text!
        } else if let textView = notif.object as? UITextView {
            // Saving description field
            exerciseDescription = textView.text!
        }
    }
    
    func stepperValueChanged(sender: UIStepper) {
        switch sender.tag {
        case 0:
            heavyReps = Int(sender.value)
        case 1:
            enduranceReps = Int(sender.value)
        case 2:
            heavySets = Int(sender.value)
        case 3:
            enduranceSets = Int(sender.value)
        default:
            return
        }
    }
    
    func addImage(sender: UIButton) {
        // Allow user to add an image and update the exercise image
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = false
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        self.image = image
        tableView.reloadData()
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            
            // Deselct all other rows
            for i in 0...self.muscleGroups.count - 1{
                let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1))
                cell?.accessoryType = UITableViewCellAccessoryType.None
                
            }
            
            // Add checkmark to the selected row and store muscle group
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
            exerciseMuscleGroup = (cell?.textLabel?.text)!
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func displayAlert(title : String, message : String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
