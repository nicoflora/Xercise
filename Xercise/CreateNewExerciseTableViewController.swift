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

class CreateNewExerciseTableViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITabBarControllerDelegate, UITabBarDelegate, UITextFieldDelegate {
    
    var sectionTitles = [String]()
    var sectionTitlesAddingFromWorkout = [String]()
    var muscleGroups = [MuscleGroup]()
    var exerciseTitle = ""
    var exerciseMuscleGroup = [String]()
    var image = UIImage(named: "new_exercise_icon")
    var exerciseDescription = ""
    var heavyReps = -1
    var enduranceReps = -1
    var heavySets = -1
    var enduranceSets = -1
    var activityIndicator = UIActivityIndicatorView()
    let constants = XerciseConstants.sharedInstance
    let dataMgr = DataManager.sharedInstance
    var addingFromWorkout = false
    var unsavedData = false
    var keyboardSize = CGSizeZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sectionTitles = constants.newExerciseTitles
        sectionTitlesAddingFromWorkout = constants.newExerciseInWorkoutTitles
        muscleGroups = constants.muscleGroupsArray
    }
    
    override func viewWillDisappear(animated: Bool) {
        tabBarController?.delegate = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        tabBarController?.delegate = self
    }
    
    @IBAction func saveExercise(sender: AnyObject) {
        
        var dataValidated = false
        // Validate Data
        if exerciseTitle.characters.count > 3 {
            if addingFromWorkout || exerciseMuscleGroup.count > 0 {
                if image != UIImage(named: "new_exercise_icon")! {
                    if exerciseDescription != constants.exerciseDescriptionText && exerciseDescription.characters.count > 10 && exerciseDescription.characters.count < 1000 {
                        if heavyReps != -1 && enduranceReps != -1 && heavySets != -1 && enduranceSets != -1 {
                            
                            // All validations passed
                            dataValidated = true
                            
                            // Create identifier
                            let uuid = CFUUIDCreateString(nil, CFUUIDCreate(nil))
                            
                            // Append reps to the description
                            exerciseDescription += "\nSuggested heavy lift (sets X reps): \(heavySets) X \(heavyReps).\nSuggested endurance lift (sets X reps): \(enduranceSets) X \(enduranceReps). "
                            
                            if addingFromWorkout == false {
                                
                                // Just adding a single exercise
                                // Prompt user for saving the exercise to the community or just on the device
                                let publicActionSheet = UIAlertController(title: nil, message: "Would you like to allow this exercise to be publicly accessible by other members of the community, or keep the exercise private?", preferredStyle: UIAlertControllerStyle.ActionSheet)
                                publicActionSheet.addAction(UIAlertAction(title: "Public", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                    
                                    // Save the exercise to the device and Parse DB
                                    if let img = UIImageJPEGRepresentation(self.image!, 0.5) {
                                        
                                        // Save to core data
                                        //self.displayActivityIndicator()
                                        self.dataMgr.saveExerciseToDevice(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                            //self.removeActivityIndicator()
                                            if success {
                                                // Saved to core data, now save to Parse
                                                // Save to Parse
                                                self.displayActivityIndicator()
                                                self.dataMgr.saveExerciseToParse(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                                    self.removeActivityIndicator()
                                                    if success {
                                                        // Present success alert and pop VC
                                                        //self.presentSucessAlert()
                                                        self.navigationController?.popViewControllerAnimated(true)
                                                    } else {
                                                        // Saving to Core Data succeeded but Parse failed
                                                        let alert = UIAlertController(title: "Public Save Error", message: "Your exercise was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                                        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                                                        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                                            //try again
                                                            self.displayActivityIndicator()
                                                            self.dataMgr.saveExerciseToParse(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                                                self.removeActivityIndicator()
                                                                if success {
                                                                    // Save to Parse was successful
                                                                    //self.presentSucessAlert()
                                                                    self.navigationController?.popViewControllerAnimated(true)
                                                                } else {
                                                                    // Parse failed again
                                                                    let alert = UIAlertController(title: "Public Save Error", message: "Your exercise was unable to be saved to the public database, but is still saved on your device.", preferredStyle: UIAlertControllerStyle.Alert)
                                                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                                                    self.presentViewController(alert, animated: true, completion: nil)
                                                                }
                                                            })
                                                        }))
                                                        self.presentViewController(alert, animated: true, completion: nil)
                                                    }
                                                })
                                            } else {
                                                self.presentAlert("Error", message: "There was an error saving your exercise. Please try again")
                                            }
                                        })
                                    } else {
                                        self.presentAlert("Error", message: "There was an error with your image, please use a different one and try again.")
                                    }
                                }))
                                publicActionSheet.addAction(UIAlertAction(title: "Private", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                    
                                    // Save the exercise to Core Data only
                                    if let img = UIImageJPEGRepresentation(self.image!, 0.5) {
                                        //self.displayActivityIndicator()
                                        self.dataMgr.saveExerciseToDevice(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                            //self.removeActivityIndicator()
                                            if success {
                                                // Present success alert and pop VC
                                                //self.presentSucessAlert()
                                                self.navigationController?.popViewControllerAnimated(true)
                                            } else {
                                                self.presentAlert("Error", message: "There was an error saving your exercise. Please try again")
                                            }
                                        })
                                    } else {
                                        self.presentAlert("Error", message: "There was an error with your image, please use a different one and try again.")
                                    }
                                }))
                                publicActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
                                self.presentViewController(publicActionSheet, animated: true, completion: nil)
                            } else {
                                // Adding an exercise inside of create workout
                                // Just save exercise to device
                                self.displayActivityIndicator()
                                if let img = UIImageJPEGRepresentation(self.image!, 0.5) {
                                    self.dataMgr.saveExerciseToDevice(self.exerciseTitle, id: uuid as String, muscleGroup: self.exerciseMuscleGroup, image: img, exerciseDescription: self.exerciseDescription, completion: { (success) -> Void in
                                        self.removeActivityIndicator()
                                        if success {
                                            // Add to NSUserDefaults to get this exercise in Create New Workout
                                            guard let mainMuscleGroup = self.exerciseMuscleGroup.first else {return}
                                            let newEntry = Entry(exerciseTitle: self.exerciseTitle, exerciseIdentifer: uuid as String, muscle_group: mainMuscleGroup)
                                            self.dataMgr.storeEntriesInDefaults([newEntry], key: "addedExercise")
                                            // Present success alert and pop VC
                                            //self.presentSucessAlert()
                                            self.navigationController?.popViewControllerAnimated(true)
                                        } else {
                                            self.presentAlert("Error", message: "There was an error saving your exercise. Please try again")
                                        }
                                    })
                                } else {
                                    self.presentAlert("Error", message: "There was an error with your image, please use a different one and try again.")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if dataValidated == false {
            presentAlert("Error!", message: "There was an error in your exercise data. Please review your data and try again.")
        }
    }
    
    func displayActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        activityIndicator.center = self.tableView.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.backgroundColor = UIColor.grayColor()
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    func removeActivityIndicator() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Tab bar controller delegate
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        // If the My Xercises Tab is selected, prompt the user of data loss before leaving the screen
        if unsavedData && viewController.tabBarItem.tag == 1 {
            presentLeaveScreenAlert({ (leave) -> Void in
                if leave {
                    // Leave page confirmed, go back to My Xercises page (root view controller)
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            })
            return false
        } else {
            return true
        }
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if addingFromWorkout {
            return sectionTitlesAddingFromWorkout.count
        } else {
            if exerciseMuscleGroup.count > 0 {
                return constants.newExerciseTitlesSubGroup.count
            } else {
                return sectionTitles.count
            }
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if addingFromWorkout {
            return sectionTitlesAddingFromWorkout[section]
        } else {
            if exerciseMuscleGroup.count > 0 {
                return constants.newExerciseTitlesSubGroup[section]
            } else {
                return sectionTitles[section]
            }

        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.lightGrayColor()
        let header = UITableViewHeaderFooterView()
        header.textLabel?.font = UIFont(name: "Marker Felt", size: 16)
        header.textLabel?.textColor = UIColor.blackColor()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if addingFromWorkout {
            return 1
        } else {
            if section == 1 {
                return muscleGroups.count
            } else if section == 2 && exerciseMuscleGroup.count > 0 {
                // Sub muscle group
                for group in muscleGroups {
                    if group.mainGroup == exerciseMuscleGroup[0] {
                        // This is the selected main group
                        return group.subGroups.count
                    }
                }
            }
        }
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if addingFromWorkout {
            switch indexPath.section {
            case 0: return 44
            case 1: return 54
            case 2: return 150
            case 3: return 85
            case 4: return 85
            default: return 44
            }
        } else {
            if exerciseMuscleGroup.count > 0 {
                switch indexPath.section {
                case 0: return 44
                case 1: return 44
                case 2: return 44
                case 3: return 54
                case 4: return 150
                case 5: return 85
                case 6: return 85
                default: return 44
                }
            } else {
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
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if addingFromWorkout {
            // If adding from a workout, do not display the muscle groups
            switch indexPath.section {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
                cell.title.tag = 1
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.saveData(_:)), name: UITextFieldTextDidChangeNotification, object: nil)
                cell.title.delegate = self
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseImage", forIndexPath: indexPath) as! ExerciseImageTableViewCell
                cell.addImageButton.addTarget(self, action: #selector(CreateNewExerciseTableViewController.addImage(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                cell.exerciseImage.image = image
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseDescription", forIndexPath: indexPath) as! ExerciseDescriptionTableViewCell
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.saveData(_:)), name: UITextViewTextDidChangeNotification, object: nil)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.removePlaceholder(_:)), name: UITextViewTextDidBeginEditingNotification, object: nil)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.replacePlaceholder(_:)), name: UITextViewTextDidEndEditingNotification, object: nil)
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseReps", forIndexPath: indexPath) as! ExerciseRepsTableViewCell
                cell.heavyStepper.tag = 0
                cell.enduranceStepper.tag = 1
                cell.heavyStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                cell.enduranceStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                return cell
            case 4:
                let cell = tableView.dequeueReusableCellWithIdentifier("exerciseSets", forIndexPath: indexPath) as! ExerciseSetsTableViewCell
                cell.heavyStepper.tag = 2
                cell.enduranceStepper.tag = 3
                cell.heavyStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                cell.enduranceStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                return cell
            default:
                let cell = UITableViewCell()
                cell.textLabel?.text = "There was an error, please try reloading the page."
                return cell
            }
        } else {
            // Not adding from workout, muscle group selection is enabled
            if exerciseMuscleGroup.count > 0 {
                // Main muscle group selection made - display sub-groups
                switch indexPath.section {
                case 0:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.saveData(_:)), name: UITextFieldTextDidChangeNotification, object: nil)
                    cell.title.delegate = self
                    return cell
                case 1:
                    let cell = UITableViewCell()
                    cell.textLabel?.text = muscleGroups[indexPath.row].mainGroup
                    cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
                    if exerciseMuscleGroup.contains(muscleGroups[indexPath.row].mainGroup) {
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                    }
                    return cell
                case 2:
                    // Sub muscle group
                    let cell = UITableViewCell()
                    for group in muscleGroups {
                        if group.mainGroup == exerciseMuscleGroup[0] {
                            // This is the selected main group
                            let subGroup = group.subGroups[indexPath.row]
                            if indexPath.row == 0 && exerciseMuscleGroup.count == 1 {
                                // Select 'All'
                                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                            }
                            cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
                            cell.textLabel?.text = subGroup
                            if exerciseMuscleGroup.contains(subGroup) {
                                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                            }
                        }
                    }
                    return cell
                case 3:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseImage", forIndexPath: indexPath) as! ExerciseImageTableViewCell
                    cell.addImageButton.addTarget(self, action: #selector(CreateNewExerciseTableViewController.addImage(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                    cell.exerciseImage.image = image
                    return cell
                case 4:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseDescription", forIndexPath: indexPath) as! ExerciseDescriptionTableViewCell
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.saveData(_:)), name: UITextViewTextDidChangeNotification, object: nil)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.removePlaceholder(_:)), name: UITextViewTextDidBeginEditingNotification, object: nil)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.replacePlaceholder(_:)), name: UITextViewTextDidEndEditingNotification, object: nil)
                    return cell
                case 5:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseReps", forIndexPath: indexPath) as! ExerciseRepsTableViewCell
                    cell.heavyStepper.tag = 0
                    cell.enduranceStepper.tag = 1
                    cell.heavyStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    cell.enduranceStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    return cell
                case 6:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseSets", forIndexPath: indexPath) as! ExerciseSetsTableViewCell
                    cell.heavyStepper.tag = 2
                    cell.enduranceStepper.tag = 3
                    cell.heavyStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    cell.enduranceStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    return cell
                default:
                    let cell = UITableViewCell()
                    cell.textLabel?.text = "There was an error, please try reloading the page."
                    return cell
                }

            } else {
                
                switch indexPath.section {
                case 0:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseTitle", forIndexPath: indexPath) as! ExerciseTitleTableViewCell
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.saveData(_:)), name: UITextFieldTextDidChangeNotification, object: nil)
                    cell.title.delegate = self
                    return cell
                case 1:
                    let cell = UITableViewCell()
                    cell.textLabel?.text = muscleGroups[indexPath.row].mainGroup
                    cell.textLabel?.font = UIFont(name: "Marker Felt", size: 20)
                    if exerciseMuscleGroup.contains(muscleGroups[indexPath.row].mainGroup) {
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                    }
                    return cell
                case 2:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseImage", forIndexPath: indexPath) as! ExerciseImageTableViewCell
                    cell.addImageButton.addTarget(self, action: #selector(CreateNewExerciseTableViewController.addImage(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                    cell.exerciseImage.image = image
                    return cell
                case 3:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseDescription", forIndexPath: indexPath) as! ExerciseDescriptionTableViewCell
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.saveData(_:)), name: UITextViewTextDidChangeNotification, object: nil)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.removePlaceholder(_:)), name: UITextViewTextDidBeginEditingNotification, object: nil)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.replacePlaceholder(_:)), name: UITextViewTextDidEndEditingNotification, object: nil)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateNewExerciseTableViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
                    return cell
                case 4:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseReps", forIndexPath: indexPath) as! ExerciseRepsTableViewCell
                    cell.heavyStepper.tag = 0
                    cell.enduranceStepper.tag = 1
                    cell.heavyStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    cell.enduranceStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    return cell
                case 5:
                    let cell = tableView.dequeueReusableCellWithIdentifier("exerciseSets", forIndexPath: indexPath) as! ExerciseSetsTableViewCell
                    cell.heavyStepper.tag = 2
                    cell.enduranceStepper.tag = 3
                    cell.heavyStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    cell.enduranceStepper.addTarget(self, action: #selector(CreateNewExerciseTableViewController.stepperValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                    return cell
                default:
                    let cell = UITableViewCell()
                    cell.textLabel?.text = "There was an error, please try reloading the page."
                    return cell
                }
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func saveData(notif : NSNotification) {
        unsavedData = true
        if let textField = notif.object as? UITextField {
            // Saving title field
            exerciseTitle = textField.text!
        } else if let textView = notif.object as? UITextView {
            // Saving description field
            exerciseDescription = textView.text!
        }
    }
    
    func removePlaceholder(notif : NSNotification) {
        // Remove placeholder if it exists
        if let textView = notif.object as? UITextView {
            if textView.textColor == UIColor.lightGrayColor() {
                textView.text = nil
                textView.textColor = UIColor.blackColor()

                // Scroll the description cell to the top of the screen to not be hidden behind the keyboard
                if addingFromWorkout {
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                } else {
                    if exerciseMuscleGroup.count > 0 {
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 4), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                    } else {
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 3), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
                    }
                }
            }
        }
    }
    
    func replacePlaceholder(notif : NSNotification) {
        if let textView = notif.object as? UITextView {
            if textView.text.isEmpty {
                textView.text = constants.exerciseDescriptionText
                textView.textColor = UIColor.lightGrayColor()
            }
        }
    }
    
    func keyboardWillShow(notif : NSNotification) {
        guard let userInfo = notif.userInfo else {return}
        guard let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size else {return}
        self.keyboardSize = keyboardSize
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
        unsavedData = true
        dismissViewControllerAnimated(true, completion: nil)
        self.image = image
        tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !addingFromWorkout {
            if indexPath.section == 1 {
                // Main muscle group
                let muscleGroup = muscleGroups[indexPath.row].mainGroup
                if exerciseMuscleGroup.contains(muscleGroup) {
                    // Was previously selected - remove from array and deselect it
                    guard let index = exerciseMuscleGroup.indexOf(muscleGroup) else {return}
                    exerciseMuscleGroup.removeAtIndex(index)
                } else {
                    // Add to array and add checkmark
                    exerciseMuscleGroup.removeAll()
                    exerciseMuscleGroup.append(muscleGroup)
                }
            } else if exerciseMuscleGroup.count > 0 && indexPath.section == 2 {
                if indexPath.row == 0 {
                    // 'All selected'
                    // Deselect all other rows
                    while exerciseMuscleGroup.count > 1 {
                        exerciseMuscleGroup.popLast()
                    }
                } else {
                    // Something other than 'All' selected
                    for group in muscleGroups {
                        if group.mainGroup == exerciseMuscleGroup[0] {
                            // This is the selected main group
                            let subGroup = group.subGroups[indexPath.row]
                            if exerciseMuscleGroup.contains(subGroup) {
                                // Remove it
                                guard let index = exerciseMuscleGroup.indexOf(subGroup) else {return}
                                exerciseMuscleGroup.removeAtIndex(index)
                            } else {
                                // Add it
                                exerciseMuscleGroup.append(subGroup)
                            }
                        }
                    }
                }
            }
            tableView.reloadData()
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func presentAlert(title : String, message : String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentSucessAlert() {
        let alert = UIAlertController(title: "Success", message: "Your exercise has been saved!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func presentLeaveScreenAlert(completion : (leave : Bool) -> Void) {
        let alert = UIAlertController(title: "Leave Screen?", message: "Leaving this current screen without saving will result in any unsaved exercise to be lost, are you sure you want to leave?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            completion(leave: false)
        }))
        alert.addAction(UIAlertAction(title: "Leave", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            completion(leave: true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
