//
//  PreferenceAccountListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 30.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import CoreData
import UIKit

class PreferenceAccountListTableViewController: UITableViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
	
	var emailAcc: EmailAccount?
	var delegate: ContentViewControllerProtocol?
	var navController: UINavigationController!
	var managedObjectContext: NSManagedObjectContext!
	var accountArr: [EmailAccount] = [EmailAccount]();
	var otherArr: [EmailAccount] = [EmailAccount]();
	var accountPreferenceCellItem: [ActionItem] = [ActionItem]()
	var newAccountItem: [ActionItem] = [ActionItem]()
	var otherItem: [ActionItem] = [ActionItem]()
	var sections = [String]()
	var rows = [AnyObject]()
	var sectionsContent = [AnyObject]()
	var loadPictures: Bool?
	var preferences: Preferences?
	var selectedTextfield: UITextField?
	var selectedIndexPath: NSIndexPath?
	var origintableViewInsets: UIEdgeInsets?
	
/*	// check if textfields are empty
	if (self.selectedTextfield != nil) {
	self.textFieldShouldReturn(self.selectedTextfield!)
	}
*/	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadCoreDataAccounts()
		tableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")
		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		tableView.registerNib(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
		self.navigationItem.title = "Accounts"
		self.sections = ["Accounts", "", ""]

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		self.accountArr.removeAll(keepCapacity: false)
		self.otherArr.removeAll(keepCapacity: false)
		self.accountPreferenceCellItem.removeAll(keepCapacity: false)
		self.newAccountItem.removeAll(keepCapacity: false)
		self.rows.removeAll(keepCapacity: false)
		self.sectionsContent.removeAll(keepCapacity: false)
		self.otherItem.removeAll(keepCapacity: false)
		
		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: "keyboardWillShow:",
			name: UIKeyboardWillShowNotification,
			object: nil)
		
		// Register notification when the keyboard will be hide
		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: "keyboardWillHide:",
			name: UIKeyboardWillHideNotification,
			object: nil)
		
		loadCoreDataAccounts()
		self.tableView.reloadData()
		
	}
	
	override func viewWillDisappear(animated: Bool) {
		var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
		var context: NSManagedObjectContext = appDel.managedObjectContext!
		var fetchRequest = NSFetchRequest(entityName: "Preferences")
		
		if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
			if fetchResults.count != 0{
				
				var managedObject = fetchResults[0]
				
				managedObject.setValue(self.preferences!.standardAccount , forKey: "standardAccount")
				managedObject.setValue(self.preferences!.signature, forKey: "signature")
				managedObject.setValue(self.loadPictures, forKey: "loadPictures")
				
			}
		}
		context.save(nil)
		
		
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// Return the number of sections.
		return self.sections.count
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.rows[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cellItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		
		// Configure the cell...
		switch cellItem.cellName {
			case "StandardAccount:":
				let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
				cell.labelCellContent.text = cellItem.cellName
				cell.textfield.placeholder = "Standard Account"
				cell.textfield.enabled = false
				cell.textfield.delegate = self
				if cellItem.emailAddress != nil {
					cell.textfield.text = cellItem.emailAddress
				}
				return cell
			case "Signature:":
				let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
				cell.labelCellContent.text = cellItem.cellName
				cell.textfield.placeholder = "Enter your signature here"
				cell.textfield.enabled = true
				cell.textfield.delegate = self
				cell.textfield.text = cellItem.emailAddress
				return cell
			case "Automaticly load pictures:":
				let cell = tableView.dequeueReusableCellWithIdentifier("SwitchTableViewCell", forIndexPath: indexPath) as! SwitchTableViewCell
				cell.label.text = cellItem.cellName
				cell.activateSwitch.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
				cell.activateSwitch.on = self.loadPictures!
				return cell
		default:
			let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell
			cell.menuLabel.text = cellItem.emailAddress
			cell.menuImg.image = cellItem.cellIcon
			
			return cell
			
		}
    }
	
	
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		var actionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem

		// Select standard Account
		if actionItem.viewController == "PreferenceStandardAccountTableView" {
			
		} else {
			// PreferenceAccountView
			var editAccountVC = PreferenceEditAccountTableViewController(nibName:"PreferenceEditAccountTableViewController", bundle: nil)
			if let emailAccountItem = self.sectionsContent[indexPath.section][indexPath.row] as? EmailAccount {
				editAccountVC.emailAcc = emailAccountItem
			}
			
			editAccountVC.actionItem = actionItem
			
			self.navigationController?.pushViewController(editAccountVC, animated: true)
			
		}
		
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		tableView.reloadData()
		
		
	}
		
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
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
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
	
	func loadCoreDataAccounts() {
		
		
		// get mail accounts from coredata
		
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			managedObjectContext = appDelegate.managedObjectContext
			var emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
			var preferencesFetchRequest = NSFetchRequest(entityName: "Preferences")
			var error: NSError?
			let acc: [EmailAccount]? = managedObjectContext.executeFetchRequest(emailAccountsFetchRequest, error: &error) as? [EmailAccount]
			if let account = acc {
				for emailAcc: EmailAccount in account {
					accountArr.append(emailAcc)
				}
			} else {
				if((error) != nil) {
					NSLog(error!.description)
				}
			}
			
			let fetchedPreferences: [Preferences]? = managedObjectContext.executeFetchRequest(preferencesFetchRequest, error: &error) as? [Preferences]
			
			if let preferences = fetchedPreferences {
				self.preferences = preferences[0]
			} else {
				if((error) != nil) {
					NSLog(error!.description)
				}
			}
			
		}
		
		// create ActionItems for mail accounts
		for emailAcc: EmailAccount in accountArr {
			var accountImage: UIImage?
			
			// set icons
			switch emailAcc.emailAddress {
			case let s where s.rangeOfString("@gmail.com") != nil:
				accountImage = UIImage(named: "Gmail-128.png")
				
			case let s where s.rangeOfString("@outlook") != nil:
				accountImage = UIImage(named: "outlook.png")
				
			case let s where s.rangeOfString("@yahoo") != nil:
				accountImage = UIImage(named: "Yahoo-icon.png")
				
			case let s where s.rangeOfString("@web.de") != nil:
				accountImage = UIImage(named: "webde.png")
				
			case let s where s.rangeOfString("@gmx") != nil:
				accountImage = UIImage(named: "gmx.png")
				
			case let s where s.rangeOfString("@me.com") != nil:
				accountImage = UIImage(named: "icloud-icon.png")
				
			case let s where s.rangeOfString("@icloud.com") != nil:
				accountImage = UIImage(named: "icloud-icon.png")
				
			case let s where s.rangeOfString("@fau.de") != nil:
				accountImage = UIImage(named: "fau-logo.png")
				
			case let s where s.rangeOfString("@studium.fau.de") != nil:
				accountImage = UIImage(named: "fau-logo.png")

			default:
				accountImage = UIImage(named: "smile-gray.png")
				
			}
			
			
			var actionItem = ActionItem(Name: emailAcc.username, viewController: "PreferenceAccountView",emailAddress: emailAcc.emailAddress, icon: accountImage)
			accountPreferenceCellItem.append(actionItem)
		}

		// Add New Account Cell
		newAccountItem.append(ActionItem(Name: "Add New Account", viewController: "CreateAccountView", emailAddress: "Add New Account", icon: UIImage(named: "ios7-plus.png")))
		
		// Preferences
		
		var standardAccountItem = ActionItem(Name: "StandardAccount:", viewController: "PreferenceStandardAccountTableView", emailAddress: preferences?.standardAccount, icon: nil)
		
		var signatureItem = ActionItem(Name: "Signature:", viewController: "", emailAddress: self.preferences?.signature, icon: nil)
		var loadPictureItem = ActionItem(Name: "Automaticly load pictures:", viewController: "", emailAddress: nil, icon: nil)
		if self.loadPictures == nil {
			self.loadPictures = preferences?.loadPictures
		}
		
		self.otherItem.append(standardAccountItem)
		self.otherItem.append(signatureItem)
		self.otherItem.append(loadPictureItem)
		
		
		self.rows.append(accountPreferenceCellItem)
		self.rows.append(newAccountItem)
		self.rows.append(otherItem)
		
		self.sectionsContent.append(accountArr)
		self.sectionsContent.append(newAccountItem)
		self.sectionsContent.append(otherItem)

	}
	
	@IBAction func menuTapped(sender: AnyObject) -> Void {
		self.delegate?.toggleLeftPanel()
	}
	
	// set value if switchstate has changed
	func stateChanged(switchState: UISwitch) {
		self.loadPictures = switchState.on
	}
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.selectedTextfield = textField
		var cellView = textField.superview
		var cell = cellView?.superview as! PreferenceAccountTableViewCell
		var indexPath = self.tableView.indexPathForCell(cell)
		self.selectedIndexPath = indexPath
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		if textField.placeholder! == "Enter your signature here" {
			self.preferences!.signature = textField.text
		}
		
		self.selectedTextfield = nil
		self.selectedIndexPath = nil
	}
	
	// return on keyboard is triggered
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	// end editing when tapping somewhere in the view
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		self.view.endEditing(true)
	}
	
	// add keyboard size to tableView size
	func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size {
			var contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height / 2, 0.0)
			
			if self.origintableViewInsets == nil {
				self.origintableViewInsets = self.tableView.contentInset
			}
			
			self.tableView.contentInset = contentInsets
			self.tableView.scrollIndicatorInsets = contentInsets
			if self.selectedIndexPath != nil {
				self.tableView.scrollToRowAtIndexPath(self.selectedIndexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
			}
		}
		
	}
	// bring tableview size back to origin
	func keyboardWillHide(notification: NSNotification) {
		if let animationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) {
			if self.origintableViewInsets != nil {
				UIView.animateWithDuration(animationDuration, animations: { () -> Void in
					self.tableView.contentInset = self.origintableViewInsets!
					self.tableView.scrollIndicatorInsets = self.origintableViewInsets!
				})
			}
		}
	}
	
}
