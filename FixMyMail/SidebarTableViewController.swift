//
//  SidebarTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 11.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import CoreData
import UIKit

/*
class ActionItem: NSObject {
    var cellIcon: UIImage?
    var cellName: String
    
    init(Name: String, icon: UIImage? = nil) {
        self.cellName = Name
        self.cellIcon = icon
    }
}
*/

class SidebarTableViewController: UITableViewController {
    
    var sections = [String]()
    var rows = [AnyObject]()
    var managedObjectContext: NSManagedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.contentInset.top = 64

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        var accountArr: [EmailAccount] = [EmailAccount]();
        let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
        if let appDelegate = appDel {
            managedObjectContext = appDelegate.managedObjectContext
            var emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
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
        }
        
        self.sections = ["Inboxes", "Accounts", ""]
        var inboxRows: [AnyObject] = [AnyObject]()
        inboxRows.append(["All"])
        for emailAcc: EmailAccount in accountArr {
            inboxRows.append(emailAcc)
        }
        /*
        var settingsArr: [ActionItem] = [ActionItem]()
        settingsArr.append(ActionItem(Name: "TODO"))
        settingsArr.append(ActionItem(Name: "Keychain"))
        settingsArr.append(ActionItem(Name: "Preferences"))
        */
        self.rows.append(inboxRows)
        self.rows.append([])
        self.rows.append([])
        //self.rows.append([settingsArr])
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows[section].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let inboxCell: SideBarTableViewCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell", forIndexPath: indexPath) as! SideBarTableViewCell
            if(indexPath.row == 0) {
                inboxCell.menuLabel.text = "All"
            } else {
                let mailAcc: EmailAccount = self.rows[indexPath.section][indexPath.row] as! EmailAccount
                inboxCell.menuLabel.text = mailAcc.username
            }
            return inboxCell
//        } else if indexPath.section == 2 {
//            let inboxCell: SideBarTableViewCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell", forIndexPath: indexPath) as! SideBarTableViewCell
//            let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
//            inboxCell.menuLabel.text = actionItem.cellName
//            if let icon = actionItem.cellIcon {
//                inboxCell.menuImg.image = icon
//            }
//            return inboxCell
        } else {
            let inboxCell: SideBarTableViewCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell", forIndexPath: indexPath) as! SideBarTableViewCell
            return inboxCell
        }
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

}
