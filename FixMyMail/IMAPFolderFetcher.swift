//
//  IMAPFolderFetcher.swift
//  FixMyMail
//
//  Created by Jan Weiß on 01.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class IMAPFolderFetcher: NSObject {
    
    var foldercount: Int! = 0
    
    static let sharedInstance: IMAPFolderFetcher = IMAPFolderFetcher()
     let managedContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
   
    func getAllIMAPFoldersWithAccounts(completion: (account: EmailAccount?, folders: [MCOIMAPFolder]?, sucess: Bool, newFolders: Bool) -> Void) -> Void {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            var fetchReq: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            var accounts: [EmailAccount] = self.managedContext.executeFetchRequest(fetchReq, error: &error) as! [EmailAccount]
            if error != nil {
                println(error!.userInfo)
                completion(account: nil, folders: nil, sucess: false, newFolders: false)
                return
            } else {
//                var semaphore = dispatch_semaphore_create(1)
                dispatch_apply(accounts.count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { (i: Int) -> Void in
                    let acc = accounts[i]
                    
                    let session = MCOIMAPSession()
                    session.hostname = acc.imapHostname
                    session.port = UInt32(acc.imapPort.unsignedIntegerValue)
                    session.username = acc.username
                    let (dictionary, error) = Locksmith.loadDataForUserAccount(acc.emailAddress)
                    if error == nil {
                        session.password = dictionary?.valueForKey("Password:") as! String
                    } else {
                        NSLog("%@", error!.description)
                        completion(account: nil, folders: nil, sucess: false, newFolders: false)
                        return
                    }
                    session.authType = StringToAuthType(acc.authTypeImap)
                    session.connectionType = StringToConnectionType(acc.connectionTypeImap)
                    
                    let folderFetch = session.fetchSubscribedFoldersOperation()
                    folderFetch.start({ (error, folders) -> Void in
                        if error != nil {
                            println(error!.userInfo)
                            completion(account: nil, folders: nil, sucess: false, newFolders: false)
                            return
                        } else {
                             var newFolders: Bool = false
                            for item in folders {
                                let fol: MCOIMAPFolder = item as! MCOIMAPFolder
                                var folWrapper: MCOIMAPFolderWrapper = MCOIMAPFolderWrapper()
                                folWrapper.path = fol.path
                                folWrapper.delimiter = fol.delimiter
                                folWrapper.flags = fol.flags
                                var fetchreq: NSFetchRequest = NSFetchRequest(entityName: "ImapFolder")
                                fetchreq.predicate = NSPredicate(format: "mcoimapfolder == %@", folWrapper)
                                var error: NSError?
                                if self.managedContext.countForFetchRequest(fetchreq, error: &error) == 0 {
                                    var folderEntity = NSEntityDescription.insertNewObjectForEntityForName("ImapFolder", inManagedObjectContext: self.managedContext) as! ImapFolder
                                    folderEntity.mcoimapfolder = folWrapper
                                    folderEntity.toEmailAccount = acc
                                    self.foldercount = self.foldercount + 1;
                                    println(folWrapper.description)
                                    newFolders = true
                                }
                                if error != nil {
                                    println(error!.userInfo)
                                }
                            }
                            var err: NSError?
                            self.managedContext.save(&err)
                            if error != nil {
                                println(err!.userInfo)
                            }
                            
                            println(self.foldercount)
                            completion(account: acc, folders: folders as! [MCOIMAPFolder]?, sucess: true, newFolders: newFolders)
//                            dispatch_semaphore_signal(semaphore)
                        }
                    })
//                    for var i: Int = 0; i < accounts.count; i++ {
//                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
//                    }
                }
            }
        })
        
    }
    
    func getIMAPFoldersForAccount(account: EmailAccount, andBlock completion: (folders: [MCOIMAPFolder]?, sucess: Bool) -> Void) -> Void {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let session = MCOIMAPSession()
            session.hostname = account.imapHostname
            session.port = UInt32(account.imapPort.unsignedIntegerValue)
            session.username = account.username
            let (dictionary, error) = Locksmith.loadDataForUserAccount(account.emailAddress)
            if error == nil {
                session.password = dictionary?.valueForKey("Password:") as! String
            } else {
                NSLog("%@", error!.description)
                completion(folders: nil, sucess: false)
                return
            }
            session.authType = StringToAuthType(account.authTypeImap)
            session.connectionType = StringToConnectionType(account.connectionTypeImap)
            
            let folderFetch = session.fetchSubscribedFoldersOperation()
            folderFetch.start({ (error, folders) -> Void in
                if error != nil {
                    println(error!.userInfo)
                    completion(folders: nil, sucess: false)
                    return
                } else {
                    for item in folders {
                        let fol: MCOIMAPFolder = item as! MCOIMAPFolder
                        var folWrapper: MCOIMAPFolderWrapper = MCOIMAPFolderWrapper()
                        folWrapper.path = fol.path
                        folWrapper.delimiter = fol.delimiter
                        folWrapper.flags = fol.flags
                        
                        var fetchReq: NSFetchRequest = NSFetchRequest(entityName: "ImapFolder")
                        fetchReq.predicate = NSPredicate(format: "mcoimapfolder == %@", folWrapper)
                        var error: NSError?
                        if self.managedContext.countForFetchRequest(fetchReq, error: &error) == 0 {
                            var folderEntity = NSEntityDescription.insertNewObjectForEntityForName("ImapFolder", inManagedObjectContext: self.managedContext) as! ImapFolder
                            folderEntity.mcoimapfolder = folWrapper
                            folderEntity.toEmailAccount = account
                            println(folWrapper.description)
                        }
                    }
                    
                    var err: NSError?
                    self.managedContext.save(&err)
                    if error != nil {
                        println(err!.userInfo)
                    }
                    
                    completion(folders: folders as! [MCOIMAPFolder]?, sucess: true)
                }
            })
        })
    }
    
}