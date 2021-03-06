//
//  MoveEmailViewController.swift
//  SMile
//
//  Created by Moritz Müller on 13.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class MoveEmailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var moveMailTableView: UITableView!
    
    var emailsToMove: NSMutableArray = NSMutableArray()
    var cellItems: [ActionItem] = []
    let leftSpaceIncrement: Float = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.moveMailTableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")
        cellItems = getSubFolderFromParentFolder(self.getActionItemsFromEmailAccount((emailsToMove.firstObject as! Email).toAccount))
        self.moveMailTableView.registerNib(UINib(nibName: "SideBarSubFolderTableViewCell", bundle: nil), forCellReuseIdentifier: "SideBarSubFolder")
        
        let buttonCancel = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "closeVCWithSender:")
        buttonCancel.tag = 1
        self.navigationItem.leftBarButtonItem = buttonCancel
        
        self.moveMailTableView.reloadData()
    }
    
    //MARK: - TableViewDelegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        /*if tableView.numberOfRowsInSection(indexPath.section) > 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell
            cell.menuImg.image = self.cellItems[indexPath.row].cellIcon
            cell.menuLabel.text = self.cellItems[indexPath.row].cellName
            if self.cellItems[indexPath.row].actionItems != nil {
                cell.menuLabel.textColor = UIColor.grayColor()
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                println(cell.menuLabel.text)
            } else {
                cell.menuLabel.textColor = UIColor.blackColor()
                cell.selectionStyle = UITableViewCellSelectionStyle.Default
            }
            return cell
        }
        return UITableViewCell()*/
        let actionItem: ActionItem = self.cellItems[indexPath.row]
        if actionItem.viewController == "NoVC" {
            let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell

            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.menuLabel.text = actionItem.cellName
            cell.menuLabel.textColor = UIColor.grayColor()
            if let icon = actionItem.cellIcon {
                cell.menuImg.image = icon
            } else {
                cell.menuImg.image = nil
            }
            return cell
            
        } else {
            var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
            let cell = viewArr[0] as! SideBarSubFolderTableViewCell
            let mailAcc: ActionItem = self.cellItems[indexPath.row]
            if mailAcc.actionItems != nil {
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.menuLabel.textColor = UIColor.grayColor()
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyle.Default
                cell.menuLabel.textColor = UIColor.blackColor()
            }
            cell.menuLabel.text = mailAcc.cellName
            self.setConstraintsForSubFolderCell(cell, andPathComponentNumber: mailAcc.pathComponentNumber)
            cell.menuImg.image = mailAcc.cellIcon
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.cellItems[indexPath.row].actionItems == nil {
            if let folder = self.cellItems[indexPath.row].emailFolder {
                for email in emailsToMove {
                    moveEmailToFolder(email as! Email, destFolder: folder.path)
                    //println("Email moved")
                }
                let button = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: "closeVCWithSender:")
                button.tag = 0
                self.closeVCWithSender(button)
            }
        } else {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    //MARK: - Supportive methods
    func closeVCWithSender(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
        if sender.tag != 1 {
            //var updatedEmails = NSMutableArray(array: (self.navigationController?.topViewController as! MailTableViewController).emails)
            //for email in emailsToMove {
                //(self.navigationController?.topViewController as! MailTableViewController).removeEmailFromArray(email as! Email)
            //}
            //(self.navigationController?.topViewController as! MailTableViewController).emails = updatedEmails.objectsAtIndexes(NSIndexSet(indexesInRange: NSRange(location: 0, length: updatedEmails.count))) as! [Email]
            //(self.navigationController?.topViewController as! MailTableViewController).emails.sort({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
            (self.navigationController?.topViewController as! MailTableViewController).endEditing()
        }
    }
    
    func getActionItemsFromEmailAccount(emailAccount: EmailAccount) -> ActionItem {
        let actionItem = ActionItem(Name: emailAccount.accountName, viewController: "NoVC", emailAccount: emailAccount, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAccount))
        var subItems = [ActionItem]()
        for imapFolder in emailAccount.folders {
            let fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
            var pathComponents = getPathComponentsFromString(fol.path)
            if pathComponents!.count > 1 {
                for var i = 0; i < (pathComponents!.count - 1); i++ {
                    let parentFolderName = pathComponents![i]
                    var parentItem: ActionItem? = self.getParentItemFromItems(subItems, andParentFolderName: parentFolderName)
                    if parentItem == nil {
                        let acItem = ActionItem(Name: pathComponents![i], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                        acItem.pathComponentNumber = i
                        acItem.actionItems = [ActionItem]()
                        parentItem = acItem
                        if i == 0 {
                            subItems.append(acItem)
                        } else {
                            self.addItemToParentItemWithItem(acItem, andParentItemName: pathComponents![i - 1])
                        }
                    }
                    if let parItem = parentItem {
                        parItem.viewController = "SubFolder"
                        if pathComponents![i + 1] != getLastPathComponentFromString(fol.path) {
                            let acItem = ActionItem(Name: pathComponents![i + 1], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                            var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                            if self.containsActionItem(acItem, inActionItemArray: subItemArr) == false {
                                subItemArr.append(acItem)
                                subItemArr = subItemArr.sort { $0.cellName < $1.cellName }
                                acItem.actionItems = subItemArr
                            }
                        } else {
                            let acItem = ActionItem(Name: pathComponents![i + 1], viewController: "EmailSpecific", emailAccount: emailAccount, icon: UIImage(named: "folder.png"), emailFolder: fol)
                            acItem.pathComponentNumber = i + 1
                            var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                            if self.containsActionItem(acItem, inActionItemArray: subItemArr) == false {
                                subItemArr.append(acItem)
                                subItemArr = subItemArr.sort { $0.cellName < $1.cellName }
                                parItem.actionItems = subItemArr
                            }
                        }
                    }
                }
            } else {
                var isParentFolder = false
                for imapFolder in emailAccount.folders {
                    let folder: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
                    let folPath: NSString = NSString(string: folder.path)
                    let range: NSRange = folPath.rangeOfString(NSString(format: "%@/", fol.path) as String)
                    if range.location != NSNotFound {
                        isParentFolder = true
                        break;
                    }
                }
                var item: ActionItem!
                if isParentFolder == true {
                    item = ActionItem(Name: fol.path, viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                } else {
                    item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAccount: emailAccount, emailFolder: fol, icon: UIImage(named: "folder.png"))
                }
                if self.containsActionItem(item, inActionItemArray: subItems) == false {
                    subItems.append(item)
                }
            }
        }
        
        
        actionItem.actionItems = subItems.sort { $0.cellName < $1.cellName }
        actionItem.folderExpanded = false
        return actionItem
    }
    
    func addItemToParentItemWithItem(childItem: ActionItem, andParentItemName parentName: String) -> Bool {
        let actionItems: [ActionItem] = self.cellItems
        var parentItem: ActionItem?
        for item in actionItems {
            if item.cellName == parentName {
                parentItem = item
                break
            }else if item.actionItems != nil && item.actionItems?.count > 0 {
                parentItem = self.getParentItemFromItems(item.actionItems!, andParentFolderName: parentName)
                if parentItem != nil {
                    break
                }
            }
        }
        if parentItem == nil {
            return false
        } else {
            var parItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
            parItemArr.append(childItem)
            parentItem?.actionItems = parItemArr.sort{ $0.cellName < $1.cellName }
            return true
        }
    }
    
    func containsActionItem(actionItem: ActionItem, inActionItemArray actionItemArray: [ActionItem]) -> Bool {
        for item in actionItemArray {
            if actionItem.cellName == item.cellName && actionItem.viewController == item.viewController &&
                actionItem.emailAccount == item.emailAccount && actionItem.cellIcon == item.cellIcon {
                    return true
            }
        }
        return false
    }
    
    func setConstraintsForSubFolderCell(cell: SideBarSubFolderTableViewCell, andPathComponentNumber pathComponentNumber: Int) -> Void {
        
        cell.menuImg.removeConstraints(cell.menuImg.constraints)
        cell.contentView.removeConstraints(cell.contentView.constraints)
        
        let constraint1: NSLayoutConstraint = NSLayoutConstraint(item: cell.menuImg, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: (CGFloat(pathComponentNumber) * CGFloat(self.leftSpaceIncrement) + 33.0))
        cell.contentView.addConstraint(constraint1)
        
        let constraint2 = NSLayoutConstraint(item: cell.menuImg, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        cell.contentView.addConstraint(constraint2)
        
        let constraint3 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Leading, relatedBy: .Equal, toItem: cell.menuImg, attribute: .Trailing, multiplier: 1.0, constant: 8.0)
        cell.contentView.addConstraint(constraint3)
        
        let constraint4 = NSLayoutConstraint(item: cell.contentView, attribute: .Trailing, relatedBy: .Equal, toItem: cell.menuLabel, attribute: .Trailing, multiplier: 1.0, constant: 20.0)
        cell.contentView.addConstraint(constraint4)
        
        let constraint5 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 11.0)
        cell.contentView.addConstraint(constraint5)
        
        let constraint6 = NSLayoutConstraint(item: cell.menuImg, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 43.0)
        cell.menuImg.addConstraint(constraint6)
        
        let constraint7 = NSLayoutConstraint(item: cell.menuImg, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 43.0)
        cell.menuImg.addConstraint(constraint7)
        
        cell.updateConstraints()
    }
    
    func getParentItemFromItems(items: [ActionItem], andParentFolderName parentFolderName: String) -> ActionItem? {
        var parentItem: ActionItem?
        for item in items {
            if item.cellName == parentFolderName {
                parentItem = item
                break;
            } else if item.actionItems != nil {
                parentItem = self.getParentItemFromItems(item.actionItems!, andParentFolderName: parentFolderName)
                if parentItem != nil {
                    break
                }
            }
        }
        return parentItem
    }
    
    func getSubFolderFromParentFolder(folder: ActionItem) -> [ActionItem] {
        var array:[ActionItem] = []
        array.append(folder)
        if folder.actionItems != nil {
            for subFolder in folder.actionItems! {
                for newFolder in getSubFolderFromParentFolder(subFolder) {
                    array.append(newFolder)
                }
            }
        }
        return array
    }
    
}
