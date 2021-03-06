//
//  AppDelegate.swift
//  FixMyMail
//
//  Created by Jan Weiß on 04.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData
//import AddressBook
import Locksmith
import Contacts

//var addressBook : ABAddressBookRef?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Needed if attaching recieved file to email
    var fileName: String?
    var fileData: NSData?
	var fileExtension: String?
	
	// needed if file is received
	var receivedFile: NSURL?

    var allAccounts: [EmailAccount] = [EmailAccount]()
    var newEmails: Int = 0
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(900)
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [UIUserNotificationType.Badge, UIUserNotificationType.Alert], categories: nil))
        
        //WARNING: This method is only for adding dummy entries to CoreData!!!*/
        self.registerUserDefaults()
	//	self.deleteAllTempFiles()
	//	self.createRingFiles()
    //    self.initCoreDataTestEntries()
	//	self.printKeys()
	//	self.cryptoTest()
			
        
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("background")
        
        completionHandler(UIBackgroundFetchResult.NewData)
        
        GetCoreDataAccounts()
        imapsynchronize()
        let count = countnewEmails()
        let notific:UILocalNotification = UILocalNotification()
        notific.applicationIconBadgeNumber = count
        if(newEmails<=count){
            notific.alertBody = "You have new Emails"
            notific.fireDate = NSDate(timeIntervalSince1970: 1)
        }
        UIApplication.sharedApplication().scheduleLocalNotification(notific)
        self.saveContext()
        
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
       
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    func imapsynchronize(){
        let folderToQuery: String = "INBOX"
        let remind:RemindMe = RemindMe()
        for account: EmailAccount in allAccounts {
            print(account.realName)
            remind.downlaodJsonAndCheckForUpcomingReminds(account)
            let currentMaxUID = getMaxUID(account, folderToQuery: folderToQuery)
            updateLocalEmail(account, folderToQuery: folderToQuery)
            fetchEmails(account, folderToQuery: folderToQuery, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        }
    }
    
    func countnewEmails()-> Int{
        var count:Int = 0
        for account in allAccounts {
            let downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
            for mail in account.emails {
                if (mail as! Email).folder == "INBOX" {
                    if let dMD = downloadMailDuration {
                        if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                            continue
                        }
                    }
                    if !((mail.mcomessage as! MCOIMAPMessage).flags.intersect(MCOMessageFlag.Seen) == MCOMessageFlag.Seen){
                        count = count+1
                    }
                }
            }
        }
        return count
    }
    
    
    func GetCoreDataAccounts(){
        allAccounts.removeAll()
        let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
        if let appDelegate = appDel {
            managedObjectContext = appDelegate.managedObjectContext
            let emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var acc: [EmailAccount]?
            do {
                acc = try managedObjectContext!.executeFetchRequest(emailAccountsFetchRequest) as? [EmailAccount]
            } catch {
                print("CoreData fetch error!")
            }
            
            if let account = acc {
                for emailAcc: EmailAccount in account {
                    allAccounts.append(emailAcc)
                }
            }
            
        }
        print("anzahl account")
        print(allAccounts.count)
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user 
        AccessAddressBook()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "de.fixMyMail.FixMyMail" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("SMile", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SMile.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
			try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
		} catch var error1 as NSError {
			error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
			fatalError()
		}
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        //objc_sync_enter(self.managedObjectContext)
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
				do {
					try moc.save()
				} catch let error1 as NSError {
					error = error1
					// Replace this implementation with code to handle the error appropriately.
					// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
					NSLog("Unresolved error \(error), \(error!.userInfo)")
					abort()
				}
			}
        }
        //objc_sync_exit(self.managedObjectContext)
    }
    
    //WARNING: This is method is only for adding dummy entries to CoreData!!!
    private func initCoreDataTestEntries() {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if(!defaults.boolForKey("TestEntriesInserted")) {
            let gmailAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
            gmailAccount.username = "fixmymail2015"
            gmailAccount.password = "*"
            gmailAccount.emailAddress = "fixmymail2015@gmail.com"
            gmailAccount.imapHostname = "imap.gmail.com"
            gmailAccount.imapPort = 993
			gmailAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			gmailAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
            gmailAccount.smtpHostname = "smtp.gmail.com"
            gmailAccount.smtpPort = 465
			gmailAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			gmailAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.TLS)
			gmailAccount.realName = "SMile_Gmail"
			gmailAccount.accountName = "Gmail"
			gmailAccount.isActivated = true
			gmailAccount.signature = ""
			gmailAccount.draftFolder = ""
			gmailAccount.sentFolder = ""
			gmailAccount.deletedFolder = ""
			gmailAccount.archiveFolder = ""
			gmailAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixmymail2015@gmail.com")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithGmail = Locksmith.deleteDataForUserAccount("fixmymail2015@gmail.com")
//			if errorLocksmithGmail == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			
			
            let gmxAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
            gmxAccount.username = "fixmymail@gmx.de"
            gmxAccount.password = "*"
            gmxAccount.emailAddress = "fixmymail@gmx.de"
            gmxAccount.imapHostname = "imap.gmx.net"
            gmxAccount.imapPort = 993
			gmxAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			gmxAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
            gmxAccount.smtpHostname = "mail.gmx.net"
            gmxAccount.smtpPort = 465
			gmxAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			gmxAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.TLS)
			gmxAccount.realName = "SMile_GMX"
            gmxAccount.accountName = "GMX"
			gmxAccount.isActivated = true
			gmxAccount.signature = "Sent with GMX!"
			gmxAccount.draftFolder = ""
			gmxAccount.sentFolder = ""
			gmxAccount.deletedFolder = ""
			gmxAccount.archiveFolder = ""
			gmxAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixmymail@gmx.de")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithGmx = Locksmith.deleteDataForUserAccount("fixmymail@gmx.de")
//			if errorLocksmithGmx == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			
            let webAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
            webAccount.username = "fixmymail@web.de"
            webAccount.password = "*"
            webAccount.emailAddress = "fixmymail@web.de"
            webAccount.imapHostname = "imap.web.de"
            webAccount.imapPort = 993
			webAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			webAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
            webAccount.smtpHostname = "smtp.web.de"
            webAccount.smtpPort = 587
			webAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			webAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.StartTLS)
			webAccount.realName = "SMile_WEBDE"
			webAccount.accountName = "WEB.DE"
			webAccount.isActivated = true
			webAccount.signature = "Sent with WEB.DE!"
			webAccount.draftFolder = ""
			webAccount.sentFolder = ""
			webAccount.deletedFolder = ""
			webAccount.archiveFolder = ""
			webAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixmymail@web.de")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithWeb = Locksmith.deleteDataForUserAccount("fixmymail@web.de")
//			if errorLocksmithWeb == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			let tcomAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
			tcomAccount.username = "fixmymail@t-online.de"
			tcomAccount.password = "*"
			tcomAccount.emailAddress = "fixmymail@t-online.de"
			tcomAccount.imapHostname = "secureimap.t-online.de"
			tcomAccount.imapPort = 993
			tcomAccount.authTypeImap = authTypeToString(MCOAuthType.SASLNone)
			tcomAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
			tcomAccount.smtpHostname = "securesmtp.t-online.de"
			tcomAccount.smtpPort = 465
			tcomAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			tcomAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.TLS)
			tcomAccount.realName = "SMile_Tcom"
			tcomAccount.accountName = "Tcom"
			tcomAccount.isActivated = true
			tcomAccount.signature = "Sent with T-Online!"
			tcomAccount.draftFolder = ""
			tcomAccount.sentFolder = ""
			tcomAccount.deletedFolder = ""
			tcomAccount.archiveFolder = ""
			tcomAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixmymail@t-online.de")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithTcom = Locksmith.deleteDataForUserAccount("fixmymail@t-online.de")
//			if errorLocksmithTcom == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			let iCloudAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
			iCloudAccount.username = "fixmymail2015"
			iCloudAccount.password = "*"
			iCloudAccount.emailAddress = "fixmymail2015@icloud.com"
			iCloudAccount.imapHostname = "imap.mail.me.com"
			iCloudAccount.imapPort = 993
			iCloudAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			iCloudAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
			iCloudAccount.smtpHostname = "smtp.mail.me.com"
			iCloudAccount.smtpPort = 587
			iCloudAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			iCloudAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.StartTLS)
			iCloudAccount.realName = "SMile_iCloud"
			iCloudAccount.accountName = "iCloud"
			iCloudAccount.isActivated = true
			iCloudAccount.signature = "Sent with iCloud"
			iCloudAccount.draftFolder = ""
			iCloudAccount.sentFolder = ""
			iCloudAccount.deletedFolder = ""
			iCloudAccount.archiveFolder = ""
			iCloudAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixmymail2015@icloud.com")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithiCloud = Locksmith.deleteDataForUserAccount("fixmymail2015@icloud.com")
//			if errorLocksmithiCloud == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			let YahooAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
			YahooAccount.username = "fixmymail2015"
			YahooAccount.password = "*"
			YahooAccount.emailAddress = "fixmymail2015@yahoo.de"
			YahooAccount.imapHostname = "imap.mail.yahoo.com"
			YahooAccount.imapPort = 993
			YahooAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			YahooAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
			YahooAccount.smtpHostname = "smtp.mail.yahoo.com"
			YahooAccount.smtpPort = 465
			YahooAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			YahooAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.TLS)
			YahooAccount.realName = "SMile_yahoo"
			YahooAccount.accountName = "Yahoo"
			YahooAccount.isActivated = true
			YahooAccount.signature = "Sent with Yahoo"
			YahooAccount.draftFolder = ""
			YahooAccount.sentFolder = ""
			YahooAccount.deletedFolder = ""
			YahooAccount.archiveFolder = ""
			YahooAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixmymail2015@yahoo.de")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithYahoo = Locksmith.deleteDataForUserAccount("fixmymail2015@yahoo.de")
//			if errorLocksmithYahoo == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			let OutlookAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
			OutlookAccount.username = "fixme2015@outlook.de"
			OutlookAccount.password = "*"
			OutlookAccount.emailAddress = "fixme2015@outlook.de"
			OutlookAccount.imapHostname = "imap-mail.outlook.com"
			OutlookAccount.imapPort = 993
			OutlookAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			OutlookAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
			OutlookAccount.smtpHostname = "smtp-mail.outlook.com"
			OutlookAccount.smtpPort = 587
			OutlookAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			OutlookAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.StartTLS)
			OutlookAccount.realName = "SMile_outlook"
			OutlookAccount.accountName = "Outlook"
			OutlookAccount.isActivated = true
			OutlookAccount.signature = "Sent with Outlook"
			OutlookAccount.draftFolder = ""
			OutlookAccount.sentFolder = ""
			OutlookAccount.deletedFolder = ""
			OutlookAccount.archiveFolder = ""
			OutlookAccount.downloadMailDuration = "Ever"
            
            do {
                try Locksmith.deleteDataForUserAccount("fixme2015@outlook.de")
            } catch _ {
                print("Locksmitherror while trying to delete useraccount!")
            }
            
//			let errorLocksmithOutlook = Locksmith.deleteDataForUserAccount("fixme2015@outlook.de")
//			if errorLocksmithOutlook == nil {
//				NSLog("found old data -> deleted!")
//			}
			
			
			
            var error: NSError?
            do {
				try self.managedObjectContext!.save()
			} catch let error1 as NSError {
				error = error1
			}
      
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                defaults.setBool(true, forKey: "TestEntriesInserted")
            }
        }
    }

    //MARK: - AdressBook
 
	func AccessAddressBook() {
		switch CNContactStore.authorizationStatusForEntityType(.Contacts) {
		case .Authorized:
			print("Already authorized")
		case .NotDetermined:
			let contactStore  = CNContactStore()
			contactStore.requestAccessForEntityType(.Contacts){succeeded, err in
				guard err == nil && succeeded else{
					print("Access not granted")
					return
				}
				print("Access granted")
			}
		case .Restricted:
			print("Access restricted")
		default:
			print("No Access")
		}
	}
 /*
    func createAddressBook(){
        var error: Unmanaged<CFError>?
        addressBook = ABAddressBookCreateWithOptions(nil, &error).takeUnretainedValue()
        if error != nil {
            print("Error while creating AddressBook: \(error)", terminator: "")
        }
    }
 */
    //MARK: - UserDefaults
    
    private func registerUserDefaults() -> Void {
        NSUserDefaults.standardUserDefaults().registerDefaults(["standardAccount" : "",
			"loadPictures" : true, "previewLines" : 1, "autoEncrypt" : false, "autoEncryptSelf" : false])
    }
	
	//MARK: - AirDrop Support and received file
		
	func application(app: UIApplication, openURL url: NSURL, options: [String: AnyObject]) -> Bool {
		let fileManager = NSFileManager.defaultManager()
		if fileManager.fileExistsAtPath(url.path!) == true {
			NSLog("File exists. File path: " + url.path!)
//			let receivedFileVC = ReceivedFileViewController(nibName: "ReceivedFileViewController", bundle: nil)
//			receivedFileVC.url = url
//			self.window?.rootViewController?.presentViewController(receivedFileVC, animated: true, completion: nil)
			self.receivedFile = url
			let rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
			self.window?.rootViewController = rootViewController
			
			
			return true
		} else {
			return false
		}
		
	}
	
	// MARK: - Setup
	
	func deleteAllTempFiles() {
		let fileManager = NSFileManager.defaultManager()
		var documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
		let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
		if paths.count > 0 {
			documentDirectory = paths[0]
		}
		// contents of document directory
		var directoryContents: [String] = [String]()
		do {
			directoryContents = try fileManager.contentsOfDirectoryAtPath(documentDirectory)
		} catch _ {
		}
		
		for path in directoryContents {
			if path == "Inbox" {
				// contents of Inbox directory
				let inboxPath = (documentDirectory as NSString).stringByAppendingPathComponent(path)
				var inboxContents: [String] = [String]()
				do {
					inboxContents = try fileManager.contentsOfDirectoryAtPath(inboxPath)
				} catch _ {
					break
				}
				// delete files in Inbox directory
				for pathInInbox in inboxContents {
					let filePath = (inboxPath as NSString).stringByAppendingPathComponent(pathInInbox)
					do {
						try fileManager.removeItemAtPath(filePath)
					} catch _ {
					}
				}
				continue
			}
			
			// delete files in document directory
			if path.rangeOfString("SMile.sqlite") == nil {
				let filePath = (documentDirectory as NSString).stringByAppendingPathComponent(path)
				do {
					try fileManager.removeItemAtPath(filePath)
				} catch _ {
				}
			}
		}
	}
	
	// MARK: - Create GPG ring files
    func createRingFiles() -> Void {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if(!defaults.boolForKey("RingfilesCreated")) {
            let fileManager = NSFileManager.defaultManager()
            let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
            let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            if paths.count > 0 {
                // create public ring file
                let dirPath = paths[0]
                let pubringPath = NSURL(fileURLWithPath: dirPath).URLByAppendingPathComponent("smile_pubring.gpg").path!
                if fileManager.createFileAtPath(pubringPath, contents: nil, attributes: nil) == false {
                    NSLog("public ringfile not created!")
                    return
                }
                
                // create secret ring file
                let secringPath = NSURL(fileURLWithPath: dirPath).URLByAppendingPathComponent("smile_secring.gpg") //dirPath.stringByAppendingPathComponent("smile_secring.gpg")
                if fileManager.createFileAtPath(secringPath.path!, contents: nil, attributes: nil) == false {
                    NSLog("secret ringfile not created!")
                    return
                }
                
                // no error checking here. if something went wrong function would have returned earlier
                defaults.setURL(NSURL(fileURLWithPath: pubringPath), forKey: "pubring")
                defaults.setURL(secringPath, forKey: "secring")
                defaults.setBool(true, forKey: "RingfilesCreated")
				
                // DEBUG
                //NSLog("pubring: " + NSURL(fileURLWithPath: pubringPath)!.path!)
                //NSLog("secring: " + NSURL(fileURLWithPath: secringPath)!.path!)
            }
        }
    }
	
	// MARK: - DELETE BEFORE RELEASE
	
	func printKeys() -> Void {
		//WARNING: DELETE BEFORE RELEASE
		let crypto = SMileCrypto()
		print("######################")
		print("KEYS IN CORE DATA")
		crypto.printAllPublicKeys()
		crypto.printAllSecretKeys()
		print("######################")
	}
	
	func cryptoTest() -> Void {
		
		//WARNING: DELETE BEFORE RELEASE
		let crypto = SMileCrypto()
        //let path = NSBundle.mainBundle().pathForResource("encTestKey", ofType: "asc")
        //let keyfile = NSURL(fileURLWithPath: path!)
		//crypto.importKey(keyfile)
		if let data = "Hallihallo PGP".dataUsingEncoding(NSUTF8StringEncoding) {
			let encryptedData = crypto.encryptData(data, keyIdentifier: "C917202C D4907952", encryptionType: "PGP")
			if encryptedData.encryptedData != nil {
				print(String(data: encryptedData.encryptedData!, encoding: NSUTF8StringEncoding))
			}

			
		}
		
		
		
/*		let fileReadError: NSError? = nil
		let path = NSBundle.mainBundle().pathForResource("PassPhrase", ofType: "txt")
		var pw = ""
		if path != nil {
			 pw = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
		}
		
		if fileReadError == nil {
			
			let data = ("THIS IS A ENCRYPTION TEST").dataUsingEncoding(NSUTF8StringEncoding)
			print("Original message: " + (NSString(data: data!, encoding: NSUTF8StringEncoding) as! String))
			let (error, encryptedData) = crypto.encryptData(data!, keyIdentifier: "42486EB9", encryptionType: "PGP")
			if error != nil {
				NSLog("Encryption Error: " + error!.localizedDescription)
			} else {
				if encryptedData != nil {
					print("Encrypted Data: " + (NSString(data: encryptedData!, encoding: NSUTF8StringEncoding) as! String))
					let (error2, decrytpedData) = crypto.decryptData(encryptedData!, passphrase: pw, encryptionType: "PGP")
					if error2 != nil {
						NSLog("Decrytption Error: " + error2!.localizedDescription)
					} else {
						if decrytpedData != nil {
							print("Decrypted Data: " + (NSString(data: decrytpedData!, encoding: NSUTF8StringEncoding) as! String))
						} else {
							NSLog("Nothing was decrytped!")
						}
						
					}
				} else {
					NSLog("Nothing was encrypted!")
				}
				
			}
		}
*/
	}

}

