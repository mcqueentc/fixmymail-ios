//
//  SidebarTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 11.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import CoreData
import UIKit

@objc
protocol SideBarProtocol {
    optional func cellSelected(actionItem: ActionItem)
}


class SidebarTableViewController: UITableViewController {
    
    @IBOutlet var sidebarCell: SideBarTableViewCell!
    var sections = [String]()
    var rows = [AnyObject]()
    var managedObjectContext: NSManagedObjectContext!
    var delegate: SideBarProtocol?
    var emailAccounts: [EmailAccount] = [EmailAccount]()
    var currAccountName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var accountArr: [EmailAccount] = [EmailAccount]();
        let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
        if let appDelegate = appDel {
            managedObjectContext = appDelegate.managedObjectContext
            var emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            let acc: [EmailAccount]? = managedObjectContext.executeFetchRequest(emailAccountsFetchRequest, error: &error) as? [EmailAccount]
            if let account = acc {
                //For fist expand comand
                self.currAccountName = self.currAccountName == nil ? account[0].accountName : self.currAccountName
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
        var inboxRows: [ActionItem] = [ActionItem]()
        inboxRows.append(ActionItem(Name: "All", viewController: "EmailAll", icon: UIImage(named: "smile-gray.png")))
        for emailAcc: EmailAccount in accountArr {
            var actionItem = ActionItem(Name: emailAcc.accountName, viewController: "EmailSpecific", emailAccount: emailAcc, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAcc))
            inboxRows.append(actionItem)
        }
        
        
        
        var settingsArr: [ActionItem] = [ActionItem]()
        settingsArr.append(ActionItem(Name: "REMIND ME!", viewController: "TODO"))
        settingsArr.append(ActionItem(Name: "Keychain", viewController: "KeyChain"))
        settingsArr.append(ActionItem(Name: "Preferences", viewController: "Preferences"))

        self.rows.append(inboxRows)
        self.rows.append(self.getIMAPFoldersFromCoreData(WithEmailAccounts: accountArr))
        self.rows.append(settingsArr)
        
        self.emailAccounts = accountArr
        self.fetchIMAPFolders()
    }
    
    override func viewWillAppear(animated: Bool) {
        if let currAccName = self.currAccountName {
            var sectionItems: [ActionItem] = self.rows[1] as! [ActionItem]
            var indexOfLastAcc: Int!
            for item in sectionItems {
                if item.cellName == self.currAccountName! {
                    indexOfLastAcc = find(sectionItems, item)
                    
                    var firstPart: [ActionItem] = Array(sectionItems[0...indexOfLastAcc])
                    var lastPart: [ActionItem]? = (sectionItems.count - 1) == indexOfLastAcc ? nil : Array(sectionItems[(indexOfLastAcc + 1)...(sectionItems.count - 1)])
                    for item: ActionItem in item.actionItems! {
                        firstPart.append(item)
                    }
                    if lastPart != nil {
                        for acItem: ActionItem in lastPart! {
                            firstPart.append(acItem)
                        }
                    }
                    self.rows[1] = firstPart
                    item.folderExpanded = true
                    self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Automatic)
                    break;
                }
            }
        }
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
            if indexPath.row == 0 {
                let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
                if let cell = inboxCell {
                    if(indexPath.row == 0) {
                        cell.menuLabel.text = "All"
                    } else {
                        cell.menuLabel.text = mailAcc.cellName
                    }
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    
                    return cell
                } else {
                    NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                    var sideBarCell: SideBarTableViewCell = self.sidebarCell
                    self.sidebarCell = nil
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    if(indexPath.row == 0) {
                        sideBarCell.menuLabel.text = "All"
                    } else {
                        sideBarCell.menuLabel.text = mailAcc.cellName
                    }
                    if let icon = mailAcc.cellIcon {
                        sideBarCell.menuImg.image = icon
                    } else {
                        sideBarCell.menuImg.image = nil
                    }
                    
                    return sideBarCell
                }
            } else {
                var accCell: AnyObject? = self.tableView.dequeueReusableCellWithIdentifier("SideBarSubFolder")
                if accCell != nil {
                    var cell = accCell as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                } else {
                    var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
                    var cell = viewArr[0] as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                }
            }
        } else if indexPath.section == 1 {
            let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
            if actionItem.viewController == "NoVC" {
                var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
                if let cell = inboxCell {
                    cell.selectionStyle = UITableViewCellSelectionStyle.Default
                    cell.menuLabel.text = actionItem.cellName
                    if let icon = actionItem.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                } else {
                    NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                    var sideBarCell: SideBarTableViewCell = self.sidebarCell
                    self.sidebarCell = nil
                    let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    if actionItem.viewController == "NoVC" {
                        sideBarCell.selectionStyle = UITableViewCellSelectionStyle.None
                    }
                    sideBarCell.menuLabel.text = actionItem.cellName
                    if let icon = actionItem.cellIcon {
                        sideBarCell.menuImg.image = icon
                    } else {
                        sideBarCell.menuImg.image = nil
                    }
                    return sideBarCell
                }
            } else {
                var accCell: AnyObject? = self.tableView.dequeueReusableCellWithIdentifier("SideBarSubFolder")
                if accCell != nil {
                    var cell = accCell as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                } else {
                    var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
                    var cell = viewArr[0] as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                }
            }
        } else if indexPath.section == 2 {
            var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
            if let cell = inboxCell {
                let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                cell.menuLabel.text = actionItem.cellName
                if let icon = actionItem.cellIcon {
                    cell.menuImg.image = icon
                } else {
                    cell.menuImg.image = nil
                }
                return cell
            } else {
                NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                var sideBarCell: SideBarTableViewCell = self.sidebarCell
                self.sidebarCell = nil
                let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                sideBarCell.menuLabel.text = actionItem.cellName
                if let icon = actionItem.cellIcon {
                    sideBarCell.menuImg.image = icon
                } else {
                    sideBarCell.menuImg.image = nil
                }
                return sideBarCell
            }
        } else {
            let inboxCell: SideBarTableViewCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as! SideBarTableViewCell
            return inboxCell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
        if actionItem.viewController != "NoVC" {
            delegate?.cellSelected!(actionItem)
        } else {
            if actionItem.actionItems != nil {
                if actionItem.folderExpanded == false {
                    var sectionItems: [ActionItem] = self.rows[indexPath.section] as! [ActionItem]
                    var firstPart: [ActionItem] = Array(sectionItems[0...indexPath.row])
                    var lastPart: [ActionItem]? = (sectionItems.count - 1) == indexPath.row ? nil : Array(sectionItems[(indexPath.row + 1)...(sectionItems.count - 1)])
                    for item: ActionItem in actionItem.actionItems! {
                        firstPart.append(item)
                    }
                    if lastPart != nil {
                        for item: ActionItem in lastPart! {
                            firstPart.append(item)
                        }
                    }
                    self.rows[indexPath.section] = firstPart
                    actionItem.folderExpanded = true
                    self.tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Automatic)
                } else {
                    var sectionItems: [ActionItem] = self.rows[indexPath.section] as! [ActionItem]
                    sectionItems.removeRange((indexPath.row + 1)...(actionItem.actionItems!.count + indexPath.row))
                    actionItem.folderExpanded = false
                    self.rows[indexPath.section] = sectionItems
                    self.tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
        }
    }
    
    //MARK: - IMAPFolder fetch
    
    private func fetchIMAPFolders() -> Void {
        IMAPFolderFetcher.sharedInstance.getAllIMAPFoldersWithAccounts { (account, folders, sucess, newFolders) -> Void in
            if sucess == true {
                var actionItems: [ActionItem] = self.rows[1] as! [ActionItem]
                let accItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAccount: account!, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
                var indexOfAccount: Int? = find(actionItems, accItem)
                if let index = indexOfAccount {
                    if index == 0 {
                        var indexTo: Int!
                        for var i = index; i < actionItems.count; i++ {
                            let item = actionItems[i]
                            if item.viewController == "NoVC" {
                                indexTo = i
                                break
                            }
                        }
                        var subArr = Array(actionItems[index...indexTo])
                        var newAccItemArr = [ActionItem]()
                        newAccItemArr.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                        for item in subArr {
                            newAccItemArr.append(item)
                        }
                        self.rows[1] = newAccItemArr
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                        })
                    } else {
                        var firstPart = Array(actionItems[0...index])
                        var indexTo: Int? = nil
                        for var i = index; i < actionItems.count; i++ {
                            let item = actionItems[i]
                            if item.viewController == "NoVC" {
                                indexTo = i
                                break
                            }
                        }
                        if indexTo == nil {
                            firstPart.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                            self.rows[1] = firstPart
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                        } else {
                            var lastPart = Array(actionItems[indexTo!...actionItems.count - 1])
                            firstPart.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                            for item in lastPart {
                                firstPart.append(item)
                            }
                            self.rows[1] = firstPart
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                        }
                    }
                } else {
                    if newFolders == true {
                        actionItems.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                        self.rows[1] = actionItems
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                        })
                    }
                }
            }
        }
    }
    
    private func getIMAPFoldersFromCoreData(WithEmailAccounts emailAccounts: [EmailAccount]) -> [ActionItem] {
        var resultItems = [ActionItem]()
        for account in emailAccounts {
            if account.folders.count > 0 {
                resultItems.append(self.getActionItemsFromEmailAccount(account, andFolders: nil))
            }
        }
        return resultItems
    }
    
    private func getActionItemsFromEmailAccount(emailAccount: EmailAccount, andFolders folders: [MCOIMAPFolder]?) -> ActionItem {
        var actionItem = ActionItem(Name: emailAccount.accountName, viewController: "NoVC", emailAccount: emailAccount, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAccount))
        var subItems = [ActionItem]()
        if folders != nil {
            for fol in folders! {
                var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAccount: emailAccount, emailFolder: fol, icon: UIImage(named: "folder.png"))
                subItems.append(item)
            }
        } else {
            for imapFolder in emailAccount.folders {
                var imapFol: ImapFolder = imapFolder as! ImapFolder
                let fol: MCOIMAPFolder = imapFol.mcoimapfolder as MCOIMAPFolder
                var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAccount: emailAccount, emailFolder: fol, icon: UIImage(named: "folder.png"))
                subItems.append(item)
            }
        }
        actionItem.actionItems = subItems.sorted { $0.cellName < $1.cellName }
        actionItem.folderExpanded = false
        return actionItem
    }

}
