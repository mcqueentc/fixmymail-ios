//
//  PreferenceEditAccountTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 02.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class PreferenceEditAccountTableViewController: UITableViewController, UITextFieldDelegate {
	
	var emailAcc: EmailAccount?
	var newEmailAcc: EmailAccount?
	var actionItem: ActionItem?
	var managedObjectContext: NSManagedObjectContext!
	var sections = [String]()
	var labelAccountDetailString = [String]()
	var labelConnectionDetailString = [String]()
	var cellAccountTextfielString = [String]()
	var cellConnectionTextfielString = [String]()
	var rows = [AnyObject]()
	var rowsEmail = [AnyObject]()
	var entries = [String: String]()
	var entriesChecked = [String: Bool]()
	var deleteString = [String]()
	var alert: UIAlertController?
	var selectedTextfield: UITextField?
	
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadAccountDetails()
		
		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		self.navigationItem.title = actionItem?.emailAddress
		var doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		self.navigationItem.rightBarButtonItem = doneButton
		self.sections = ["Account Details:", "", "Connection Details:", ""]
		
		// set alert dialog
	    alert = UIAlertController(title: "Delete", message: "Really delete account?", preferredStyle: UIAlertControllerStyle.Alert)
		self.alert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
			// save data to CoreData
			var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			var context: NSManagedObjectContext = appDel.managedObjectContext!
			var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
			fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", self.emailAcc!.emailAddress)
			
			if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
				if fetchResults.count != 0{
					
					var managedObject = fetchResults[0]
					context.deleteObject(managedObject)
				}
			}
			
			context.save(nil)
			self.navigationController?.popViewControllerAnimated(true)
		}))
		
		self.alert!.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
		}))
	
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
    }

	override func viewWillAppear(animated: Bool) {
		self.tableView.reloadData()
		
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

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		// show alert dialog
		if self.rows[indexPath.section][indexPath.row] as? String == "DELETE" {
			self.presentViewController(self.alert!, animated: true, completion: nil)
		}
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell

        // Configure the cell...
		cell.textfield.delegate = self
		cell.labelCellContent.text = self.rows[indexPath.section][indexPath.row] as? String
		cell.textfield.placeholder = self.rows[indexPath.section][indexPath.row] as? String
		
		// set checkmarks on cell
		if self.entriesChecked[cell.labelCellContent.text!] == true {
			cell.accessoryType = UITableViewCellAccessoryType.Checkmark
		} else {
			cell.accessoryType = UITableViewCellAccessoryType.None
		}

		// secure text entry for password cell
		if cell.textfield.placeholder == "Password:" {
			cell.textfield.secureTextEntry = true
		} else {
			cell.textfield.secureTextEntry = false
		}
	
		if emailAcc != nil {
			cell.textfield.text = self.entries[cell.labelCellContent.text!]
			cell.labelCellContent.textAlignment = NSTextAlignment.Left
			cell.textfield.enabled = true
			self.entriesChecked[cell.labelCellContent.text!] = false
			
			// configure delete cell
			if cell.labelCellContent.text == deleteString[0] {
				cell.labelCellContent.textAlignment = NSTextAlignment.Center
				cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
				cell.textfield.text = ""
				cell.textfield.placeholder = ""
				cell.textfield.enabled = false
				self.entries.removeValueForKey(self.deleteString[0])
				self.entriesChecked.removeValueForKey(self.deleteString[0])
			}
		}
		
        return cell
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
	
	func loadAccountDetails() {
		
		self.labelAccountDetailString.append("Mailaddress:")
		self.labelAccountDetailString.append("Username:")
		self.labelAccountDetailString.append("Password:")
		self.labelConnectionDetailString.append("IMAP Hostname:")
		self.labelConnectionDetailString.append("IMAP Port:")
		self.labelConnectionDetailString.append("SMTP Hostname:")
		self.labelConnectionDetailString.append("SMTP Port:")
		
		if emailAcc != nil {
			self.cellAccountTextfielString.append(emailAcc!.emailAddress)
			self.cellAccountTextfielString.append(emailAcc!.username)
			self.cellAccountTextfielString.append(emailAcc!.password)
			self.cellConnectionTextfielString.append(emailAcc!.imapHostname)
			self.cellConnectionTextfielString.append(String(Int(emailAcc!.imapPort)))
			self.cellConnectionTextfielString.append(emailAcc!.smtpHostname)
			self.cellConnectionTextfielString.append(String(Int(emailAcc!.smtpPort)))
			
			self.entries["Mailaddress:"] = emailAcc!.emailAddress
			self.entries["Username:"] = emailAcc!.username
			self.entries["Password:"] = emailAcc!.password
			self.entries["IMAP Hostname:"] = emailAcc!.imapHostname
			self.entries["IMAP Port:"] = String(Int(emailAcc!.imapPort))
			self.entries["SMTP Hostname:"] = emailAcc!.smtpHostname
			self.entries["SMTP Port:"] = String(Int(emailAcc!.smtpPort))
		} else {
			self.entries["Mailaddress:"] = ""
			self.entries["Username:"] = ""
			self.entries["Password:"] = ""
			self.entries["IMAP Hostname:"] = ""
			self.entries["IMAP Port:"] = ""
			self.entries["SMTP Hostname:"] = ""
			self.entries["SMTP Port:"] = ""
		}
		
		if actionItem?.emailAddress != "Add New Account" {
			self.deleteString.append("DELETE")
		}
		
		rows.append(self.labelAccountDetailString)
		rows.append([])
		rows.append(self.labelConnectionDetailString)
		rows.append(self.deleteString)
		
		rowsEmail.append(self.cellAccountTextfielString)
		rowsEmail.append([])
		rowsEmail.append(self.cellConnectionTextfielString)
		rowsEmail.append(self.deleteString)
		
	}
	
	@IBAction func doneTapped(sender: AnyObject) -> Void {
		
		self.navigationItem.rightBarButtonItem?.enabled = false
		
		// check if textfields are empty
		if (self.selectedTextfield != nil) {
			self.textFieldShouldReturn(self.selectedTextfield!)
		}
		
		for (key, value) in self.entriesChecked{
			self.entriesChecked[key] = false
		}
		self.tableView.reloadData()
		if self.allEntriesSet() {
			// test the imap connection
			var imapOperation = self.getImapOperation()
			imapOperation.start({(NSError error) in
				if (error != nil) {
					NSLog("can't establish Imap connection: %@", error)
					var alert = UIAlertController(title: "Error", message: "Your Properties for IMAP seem to be wrong!", preferredStyle: UIAlertControllerStyle.Alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
					self.presentViewController(alert, animated: true, completion: nil)
					self.navigationItem.rightBarButtonItem?.enabled = true
					return
					
					
				} else {
					println("Imap connection valid")
					self.entriesChecked["IMAP Hostname:"] = true
					self.entriesChecked["IMAP Port:"] = true
					self.entriesChecked["Username:"] = true
					self.entriesChecked["Password:"] = true
					self.tableView.reloadData()
					// imap connection valid -> test the smtp connection
					var smtpOperation = self.getSmtpOperation()
					smtpOperation.start({(NSError error) in
						if (error != nil) {
							NSLog("can't establish Smpt connection: %@", error)
							var alert = UIAlertController(title: "Error", message: "Your Properties for SMTP seem to be wrong!", preferredStyle: UIAlertControllerStyle.Alert)
							alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
							self.presentViewController(alert, animated: true, completion: nil)
							self.navigationItem.rightBarButtonItem?.enabled = true
							return
							
							
						} else {
							println("Smpt connection valid")
							self.entriesChecked["SMTP Hostname:"] = true
							self.entriesChecked["SMTP Port:"] = true
							self.entriesChecked["Username:"] = true
							self.entriesChecked["Password:"] = true
							self.tableView.reloadData()
							// imap and smtp connections returned valid
							// write | update entity
							var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
							var context: NSManagedObjectContext = appDel.managedObjectContext!
							
							if self.actionItem?.emailAddress == "Add New Account" {
								var newEntry = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: context) as!EmailAccount
								
								for (key, value) in self.entries {
									switch key {
									case "Mailaddress:": 	newEntry.setValue(value, forKey: "emailAddress")
									case "Username:": 	newEntry.setValue(value, forKey: "username")
									case "Password:": 		newEntry.setValue(value, forKey: "password")
									case "IMAP Hostname:": 	newEntry.setValue(value, forKey: "imapHostname")
									case "IMAP Port:": 		newEntry.setValue(value.toInt(), forKey: "imapPort")
									case "SMTP Hostname:": 	newEntry.setValue(value, forKey: "smtpHostname")
									case "SMTP Port:": 		newEntry.setValue(value.toInt(), forKey: "smtpPort")
									default: break
									}
								}
							} else {
								
								var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
								fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", self.emailAcc!.emailAddress)
								
								if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
									if fetchResults.count != 0{
										
										var managedObject = fetchResults[0]
										
										for (key, value) in self.entries {
											switch key {
											case "Mailaddress:": 	managedObject.setValue(value, forKey: "emailAddress")
											case "Username:": 		managedObject.setValue(value, forKey: "username")
											case "Password:": 		managedObject.setValue(value, forKey: "password")
											case "IMAP Hostname:": 	managedObject.setValue(value, forKey: "imapHostname")
											case "IMAP Port:": 		managedObject.setValue(value.toInt(), forKey: "imapPort")
											case "SMTP Hostname:": 	managedObject.setValue(value, forKey: "smtpHostname")
											case "SMTP Port:": 		managedObject.setValue(value.toInt(), forKey: "smtpPort")
											default: break
											}
										}
									}
								}
							}
							context.save(nil)
							self.navigationController?.popViewControllerAnimated(true)
						}
					})
					
				}
			})
		
		}
		
		else {
			self.navigationItem.rightBarButtonItem?.enabled = true
		}
	}

	func checkAllTextfieldsFilled() {
		for var section = 0; section < self.tableView.numberOfSections(); section++ {
			for var row = 0; row < self.tableView.numberOfRowsInSection(section); row++ {
				var cellPath = NSIndexPath(forRow: row, inSection: section)
				if let cell = self.tableView.cellForRowAtIndexPath(cellPath) as? PreferenceAccountTableViewCell {
					
					if cell.textfield.text.isEmpty {
						cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
					} else {
						cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.blackColor()])
						
					}
				}
			}
		}
	}
	
	func allEntriesSet() -> Bool {
		for (key, value) in self.entries {
			
			if value == "" {
				checkAllTextfieldsFilled()
				return false
			}
		}
		checkAllTextfieldsFilled()
		return true
	}
	
	func getImapOperation() -> MCOIMAPOperation {
		
		var session = MCOIMAPSession()
		session.hostname = self.entries["IMAP Hostname:"]
		session.port = uint(self.entries["IMAP Port:"]!.toInt()!)
		session.username = self.entries["Username:"]
		session.password = self.entries["Password:"]
		session.connectionType = MCOConnectionType.TLS
		session.authType = MCOAuthType.SASLPlain
		var address: MCOAddress = MCOAddress(mailbox: self.entries["Mailaddress:"])
		let op = session.checkAccountOperation()
		return op!
		
	}
	
	func getSmtpOperation() -> MCOSMTPOperation {
		var session = MCOSMTPSession()
		session.hostname = self.entries["SMTP Hostname:"]
		session.port = uint(self.entries["SMTP Port:"]!.toInt()!)
		session.username = self.entries["Username:"]
		session.password = self.entries["Password:"]
		session.connectionType = MCOConnectionType.TLS
		session.authType = MCOAuthType.SASLPlain
		var address: MCOAddress = MCOAddress(mailbox: self.entries["Mailaddress:"])
		let op = session.checkAccountOperationWithFrom(address)
		return op
	}
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.selectedTextfield = textField
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		
		if textField.placeholder! == "Mailaddress:" {
			// check if mail address
			if !(textField.text.rangeOfString("@") != nil) {
				textField.text = ""
			}
		}
		
		// check if port entries are numbers
		if textField.placeholder! == "IMAP Port:" || textField.placeholder! == "SMTP Port:" {
			if textField.text.toInt() == nil {
				textField.text = ""
			}
		}
		// save data to entries
		self.entries[textField.placeholder!] = textField.text
		self.entriesChecked[textField.placeholder!] = false
		
		

	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		self.view.endEditing(true)
	}
	
}