//
//  SMileCrypto.swift
//  SMile
//
//  Created by Sebastian Thürauf on 30.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

// example for use in other classes:
// var crypt = SMileCrypto()
// var edata: NSData = crypt.encryptString("Hello from swift my little swifty", key: "SMile")
// println("encrytpted: \(edata)")
// var pdata: String = crypt.decryptData(edata, key: "SMile")
// println("decrypted: \(pdata)")


import UIKit
import CoreData

class SMileCrypto: NSObject {
	private var pgp: ObjectivePGP
	private var unnetpgp: UNNetPGP
	private var fileManager: NSFileManager
	private var pubringURL: NSURL
	private var secringURL: NSURL
	private var documentDirectory: String
	private var keysInCoreData: [Key]?
	private var managedObjectContext: NSManagedObjectContext?
	
	enum TrustType: Int {
		case Unknown = 1
		case Never = 2
		case Marginally = 3
		case Fully = 4
		case Ultimately = 5
	}
	
	
	
	
	override init() {
		self.pgp = ObjectivePGP()
		self.unnetpgp = UNNetPGP()
		self.fileManager = NSFileManager.defaultManager()
		self.pubringURL = NSUserDefaults.standardUserDefaults().URLForKey("pubring")!
		self.secringURL = NSUserDefaults.standardUserDefaults().URLForKey("secring")!
		
		// pgp settings
	//	self.pgp.importKeysFromFile(self.pubringURL.path!, allowDuplicates: false)
	//	self.pgp.importKeysFromFile(self.secringURL.path!, allowDuplicates: false)
		
		// get documentDirectory
		self.documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
		if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
			if paths.count > 0 {
				if let dirPath = paths[0] as? String {
					self.documentDirectory = dirPath
				}
			}
		}
		
		// fetch key from coreData and load them to ObjectivePGP
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			self.managedObjectContext = appDelegate.managedObjectContext!
			var keyFetchRequest = NSFetchRequest(entityName: "Key")
			var error: NSError?
			self.keysInCoreData = managedObjectContext!.executeFetchRequest(keyFetchRequest, error: &error) as? [Key]
			if self.keysInCoreData != nil {
				if self.keysInCoreData!.count > 0 {
					for key in self.keysInCoreData! {
						pgp.importKeysFromData(key.keyData, allowDuplicates: false)
					}
				} else {
					self.keysInCoreData = nil
				}
			}
			
		}
	
	}
/*
	init(pgp: ObjectivePGP, unnetpgp: UNNetPGP, fileManager: NSFileManager, pubringURL: NSURL, secringURL: NSURL) {
		self.pgp = pgp
		self.unnetpgp = unnetpgp
		self.fileManager = fileManager
		self.pubringURL = pubringURL
		self.secringURL = secringURL
		
		// pgp settings
	//	self.pgp.importKeysFromFile(self.pubringURL.path!, allowDuplicates: false)
	//	self.pgp.importKeysFromFile(self.secringURL.path!, allowDuplicates: false)
		
		// get documentDirectory
		self.documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
		if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
			if paths.count > 0 {
				if let dirPath = paths[0] as? String {
					self.documentDirectory = dirPath
				}
			}
		}
		
		// fetch key from coreData and load them to ObjectivePGP
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			self.managedObjectContext = appDelegate.managedObjectContext!
			var keyFetchRequest = NSFetchRequest(entityName: "Key")
			var error: NSError?
			self.keysInCoreData = managedObjectContext!.executeFetchRequest(keyFetchRequest, error: &error) as? [Key]
			if self.keysInCoreData != nil {
				for key in self.keysInCoreData! {
					pgp.importKeysFromData(key.keyData, allowDuplicates: false)
				}
			}
			
		}
		
	}
*/
	// MARK: - Decryption
	/**
	Decrypt File
	
	:param: encryptedFile:	the encrypted file at URL.
	:param: passphrase:	the passphrase to unlock the private key.
	:param: encryptionType:	PGP or SMIME
	
	:returns: The Error or nil if decrypt was successful.
			  Decrytped File at URL or nil if error occured.
	*/
	func decryptFile(encryptedFile: NSURL, passphrase: String, encryptionType: String) -> (NSError?, NSURL?) {
		var error: NSError?
		var decryptedFile: NSURL?
		var encryptedData: NSData?
		var decryptedData: NSData?
		
		var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory.stringByAppendingPathComponent(self.fileManager.displayNameAtPath(encryptedFile.path!)))!
		
		self.fileManager.copyItemAtURL(encryptedFile, toURL: copyItem, error: &error)
		if error == nil {
			if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
				encryptedData = NSData(contentsOfURL: copyItem)
				if encryptedData != nil {
					decryptedData = self.pgp.decryptData(encryptedData!, passphrase: passphrase, error: &error)
					if decryptedData != nil && error == nil {
						// cut of .asc or .gpg to get the original extention
						// for files not conforming to encrypted filenames like test.pdf.asc we have to implement some magic number checking
						var newFilePath: String = (copyItem.path! as NSString).substringToIndex((copyItem.path! as NSString).length - 4)
						if self.fileManager.createFileAtPath(newFilePath, contents: decryptedData, attributes: nil) == true {
							decryptedFile = NSURL(fileURLWithPath: newFilePath)
						}
					}
				}
			} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
				// TODO
				// Do smime stuff
			}
			
	/*
			self.unnetpgp = UNNetPGP(userId: "fixmymail2015@gmail.com")
			self.unnetpgp.armored = true
			self.unnetpgp.publicKeyRingPath = self.pubringURL.path!
			self.unnetpgp.secretKeyRingPath = self.secringURL.path!
			self.unnetpgp.password = passphrase
			var newFilePath: String = (copyItem.path! as NSString).substringToIndex((copyItem.path! as NSString).length - 4)
			
			self.unnetpgp.decryptFileAtPath(copyItem.path!, toFileAtPath: newFilePath)
			decryptedFile = NSURL(fileURLWithPath: newFilePath)
	*/	
			
		}
		return (error, decryptedFile)
	}
	
	/**
		Decrypt Data
	
		:param: data:	the encrypted data.
		:param: passphrase:	the passphrase to unlock the private key.
		:param: encryptionType:	PGP or SMIME
	
		:returns: The Error or nil if decrypt was successful
				  and Decrytped Data or nil if error occured.
 	*/
	func decryptData(data: NSData, passphrase: String, encryptionType: String) -> (NSError?, NSData?) {
		var error: NSError?
		var decryptedData: NSData?
		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
			decryptedData = self.pgp.decryptData(data, passphrase: passphrase, error: &error)
			
		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
			// TODO
			// Do smime stuff
		}
		
		
		return (error, decryptedData)
	}
	
	// MARK: - Encryption
	/**
	Encrypt File
	
	:param: file:	the file to be encrypted.
	:param: keyIdentifier:	the key ID full or short.
	:param: encryptionType:	PGP or SMIME
	
	:returns: The Error or nil if encrypt was successful
	and encrytped Data or nil if error occured.
	*/
	func encryptFile(file: NSURL, keyIdentifier: String, encryptionType: String) -> (NSError?, NSURL?) {
		var error: NSError?
		var encryptedFile: NSURL?
		var encryptedData: NSData?
		var dataToEncrypt: NSData?
		
		var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory.stringByAppendingPathComponent(self.fileManager.displayNameAtPath(file.path!)))!
		self.fileManager.copyItemAtURL(file, toURL: copyItem, error: &error)
		if error == nil {
			if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
				dataToEncrypt = NSData(contentsOfURL: copyItem)
				if dataToEncrypt != nil {
					var keyToEncrypt: PGPKey = self.pgp.getKeyForIdentifier(keyIdentifier, type: PGPKeyType.Public)
					NSLog(NSString(data: keyToEncrypt.primaryKeyPacket.headerData, encoding: NSUTF8StringEncoding) as! String)
					encryptedData = self.pgp.encryptData(dataToEncrypt!, usingPublicKey: keyToEncrypt, armored: true, error: &error)
					if encryptedData != nil && error == nil {
						var newFilePath: String = copyItem.path! + ".asc"
						if self.fileManager.createFileAtPath(newFilePath, contents: encryptedData!, attributes: nil) == true {
							encryptedFile = NSURL(fileURLWithPath: newFilePath)
						}
					}
				}
				
				
			} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
				// TODO
				// Do smime stuff
			}
		}
		
		return (error, encryptedFile)
	}
	
	
	/**
	Encrypt Data
	
	:param: data:	the data to be encrypted.
	:param: keyIdentifier:	the key ID full or short.
	:param: encryptionType:	PGP or SMIME
	
	:returns: The Error or nil if encrypt was successful
			  and encrytped Data or nil if error occured.
	*/
	func encryptData(data: NSData, keyIdentifier: String, encryptionType: String) -> (NSError?, NSData?) {
		var error: NSError?
		var encryptedData: NSData?
		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
			var keyToEncrypt: PGPKey = self.pgp.getKeyForIdentifier(keyIdentifier, type: PGPKeyType.Public)
						
			encryptedData = self.pgp.encryptData(data, usingPublicKey: keyToEncrypt, armored: true, error: &error)
			
		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
			// TODO
			// Do smime stuff
		}
		
		
		return (error, encryptedData)
	}
	
	// MARK: - Import Keys
	/**
	Import Key
	
	:param: keyfile:	the URL of the keyfile to be imported.
	
	:returns: true if import was successful.
	*/
	func importKey(keyfile: NSURL) -> Bool {
		var resultPublic: Bool?
		var resultSecret: Bool?
		var exportError: NSError?
		if let fileContent = String(contentsOfFile: keyfile.path!, encoding: NSUTF8StringEncoding, error: nil) {
			// extract and import public key block
			if fileContent.rangeOfString("-----BEGIN PGP PUBLIC KEY BLOCK-----") != nil {
				var beginRange = fileContent.rangeOfString("-----BEGIN PGP PUBLIC KEY BLOCK-----")
				var endRange = fileContent.rangeOfString("-----END PGP PUBLIC KEY BLOCK-----")
				if beginRange != nil && endRange != nil {
					var pubKeyBlock = fileContent.substringWithRange(Range<String.Index>(start: beginRange!.startIndex, end: endRange!.endIndex))
				//	NSLog("pubKeyBlock: \n" + pubKeyBlock)
				//	NSLog("fileContent: \n" + fileContent)
					var keyData: NSData = pubKeyBlock.dataUsingEncoding(NSUTF8StringEncoding)!
					var importedOjbects = pgp.importKeysFromData(keyData, allowDuplicates: false)
					resultPublic = importedOjbects.count > 0
					// DEBUG
					if resultPublic != nil {
						NSLog("Public key imported")
					}

				}
			
			}
			// extract and import private key block
			if fileContent.rangeOfString("-----BEGIN PGP PRIVATE KEY BLOCK-----") != nil {
				var beginRange = fileContent.rangeOfString("-----BEGIN PGP PRIVATE KEY BLOCK-----")
				var endRange = fileContent.rangeOfString("-----END PGP PRIVATE KEY BLOCK-----")
				if beginRange != nil && endRange != nil {
					var secKeyBlock = fileContent.substringWithRange(Range<String.Index>(start: beginRange!.startIndex, end: endRange!.endIndex))
				//	NSLog("secKeyBlock: " + secKeyBlock)
					var keyData: NSData = secKeyBlock.dataUsingEncoding(NSUTF8StringEncoding)!
					var importedOjbects = pgp.importKeysFromData(keyData, allowDuplicates: false)
					resultSecret = importedOjbects.count > 0
					// DEBUG
					if resultSecret != nil {
						NSLog("Secret key imported")
					}
				}
			}
			
			if fileContent.rangeOfString("pkcs7-mime") != nil {
				// TODO
				// do smime stuff
			}

		}
		
		
		
		// save new pubkeys to core data
		var pubKeys: NSArray = pgp.getKeysOfType(PGPKeyType.Public)
		for anyPubkey in pubKeys {
			let pubkey = anyPubkey as! PGPKey
			// check if pubkey already exists in core data
			var isPresent: Bool = false
			if self.keysInCoreData != nil {
				for key in self.keysInCoreData! {
					if key.isPublicKey {
						if key.keyID == pubkey.keyID.longKeyString {
							isPresent == true
							break
						}
					}
				}
			}
			if isPresent == false {
				// save new pubkey to core data
				var newKeyToSave = self.getKeyFromPGPKey(pubkey)
				var success = self.saveKeyToCoreData(newKeyToSave)
				if success {
					if self.keysInCoreData != nil {
						self.keysInCoreData!.append(newKeyToSave)
					} else {
						self.keysInCoreData = [Key]()
						self.keysInCoreData!.append(newKeyToSave)
					}
				}
			}
		}
		
		// save new seckeys to core data
		var secKeys: NSArray = pgp.getKeysOfType(PGPKeyType.Secret)
		for anySecKey in secKeys {
			let secKey = anySecKey as! PGPKey
			// check if seckey already exists in core data
			var isPresent: Bool = false
			if self.keysInCoreData != nil {
				for key in self.keysInCoreData! {
					if key.isSecretKey {
						if key.keyID == secKey.keyID.longKeyString {
							isPresent == true
							break
						}
					}
				}
			}
			if isPresent == false {
				// save new seckey to core data
				var newKeyToSave = self.getKeyFromPGPKey(secKey)
				var success = self.saveKeyToCoreData(newKeyToSave)
				if success {
					if self.keysInCoreData != nil {
						self.keysInCoreData!.append(newKeyToSave)
					} else {
						self.keysInCoreData = [Key]()
						self.keysInCoreData!.append(newKeyToSave)
					}
				}
			}
			
		}

		
		
		
/*
		// self delete dublicates because it is not working with private keys
		// TODO #######
		var pubKeys: NSArray = pgp.getKeysOfType(PGPKeyType.Public)
		var secKeys: NSArray = pgp.getKeysOfType(PGPKeyType.Secret)
		var pubKeysArray: NSArray = [PGPKey]()
		var secKeysArray: NSArray = [PGPKey]()
		
		var uniqueSecKeys: NSSet = NSSet(array: secKeys as! [PGPKey])
		secKeys = uniqueSecKeys.allObjects as AnyObject as! NSArray
		
		var allKeys = NSArray(array: pubKeys.arrayByAddingObjectsFromArray(secKeys as [AnyObject]))
		pgp.keys = allKeys as [AnyObject]

		//##########
		

		self.fileManager.createFileAtPath(self.pubringURL.path!, contents: nil, attributes: nil)
		self.fileManager.createFileAtPath(self.secringURL.path!, contents: nil, attributes: nil)
		
		pgp.exportKeysOfType(PGPKeyType.Public, toFile: self.pubringURL.path!, error: &exportError)
		pgp.exportKeysOfType(PGPKeyType.RawValue, toFile: self.secringURL.path!, error: &exportError)
		if exportError != nil {
			NSLog("Error: \(exportError?.domain)")
		} else {
			//NSLog("Export of imported keys to ringfile successful")
		}
*/
		if resultPublic != nil && resultSecret != nil {
			return resultSecret! && resultPublic!
		} else if resultPublic != nil && resultSecret == nil {
			return resultPublic!
		} else if resultPublic == nil && resultSecret != nil {
			return resultSecret!
		} else {
			return false
		}
	}
	
	// MARK: - Encrypt Strings with password
	func encryptString(estring: String, key: String) -> NSData {
		var edata = MyRNEncryptor.encryptData(estring.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), password: key, error: nil)
		
		return edata
	}
	
	func decryptData(edata: NSData, key: String) -> String {
		
		var pdata = RNDecryptor.decryptData(edata, withPassword: key, error: nil)
		var pstring: String = MyRNEncryptor.stringFromData(pdata)
		return pstring
	}
	
	// MARK: - DEBUG
	
	/**
	Print all public keys
	
	:param: fromActiveInstance:	true: all public keys from pgp instance.
							    false: all public keys from core data.
	
	*/
	func printAllPublicKeys(fromActiveInstance: Bool) {
		var pubKeyStrings: [String] = [String]()
		if fromActiveInstance {
			var pubkeys = pgp.getKeysOfType(PGPKeyType.Public) as! [PGPKey]
			for key in pubkeys {
				pubKeyStrings.append(key.keyID.shortKeyString)
			}
			println("Public Keys: " + ",".join(pubKeyStrings))
		} else {
			var keyFetchRequest = NSFetchRequest(entityName: "Key")
			var error: NSError?
			var fetchedKeysFromCoreData = managedObjectContext!.executeFetchRequest(keyFetchRequest, error: &error) as? [Key]
			if error != nil {
				NSLog("Public Key fetchRequest: \(error?.localizedDescription)")
			} else {
				for key in fetchedKeysFromCoreData! {
					pubKeyStrings.append(key.keyID)
				}
			}
			println("Public Keys: " + ",".join(pubKeyStrings))
		}
	}
	
	/**
	Print all secret keys
	
	:param: fromActiveInstance:	true: all secret keys from pgp instance.
	false: all secret keys from core data.
	
	*/
	func printAllSecretKeys(fromActiveInstance: Bool) {
		var secKeyStrings: [String] = [String]()
		if fromActiveInstance {
			var seckeys = pgp.getKeysOfType(PGPKeyType.Secret) as! [PGPKey]
			for key in seckeys {
				secKeyStrings.append(key.keyID.shortKeyString)
			}
			println("Secret Keys: " + ",".join(secKeyStrings))
		} else {
			var keyFetchRequest = NSFetchRequest(entityName: "Key")
			var error: NSError?
			var fetchedKeysFromCoreData = managedObjectContext!.executeFetchRequest(keyFetchRequest, error: &error) as? [Key]
			if error != nil {
				NSLog("Secret Key fetchRequest: \(error?.localizedDescription)")
			} else {
				for key in fetchedKeysFromCoreData! {
					secKeyStrings.append(key.keyID)
				}
			}
			println("Secret Keys: " + ",".join(secKeyStrings))
		}
	}

	func getKeyFromPGPKey(pgpKey: PGPKey) -> Key {
		var newKey = Key()
/*		newKey.userIDprimary = (pgpKey.users.firstObject as! PGPUser).userID
		newKey.emailAddressPrimary = ""
		newKey.keyID = pgpKey.keyID.longKeyString
		newKey.isSecretKey = pgpKey.type == PGPKeyType.Secret
		newKey.isPublicKey = pgpKey.type == PGPKeyType.Public
		newKey.keyType = "PGP"
		newKey.created = (pgpKey.primaryKeyPacket as! PGPPublicKeyPacket).createDate
		newKey.validThru = NSDate(timeInterval: Double((pgpKey.primaryKeyPacket as! PGPPublicKeyPacket).V3validityPeriod), sinceDate: newKey.created)
		newKey.keyLength = (pgpKey.primaryKeyPacket as! PGPPublicKeyPacket).keySize
		newKey.algorithm = self.getAlgorithmString(Int((pgpKey.primaryKeyPacket as! PGPPublicKeyPacket).publicKeyAlgorithm.rawValue))
		newKey.fingerprint = (pgpKey.primaryKeyPacket as! PGPPublicKeyPacket).fingerprint.description()
		newKey.trust = TrustType.Unknown.rawValue
		
		var userIDs: [UserID] = [UserID]()
		for var i = 0; i < pgpKey.users.count; i++ {
			var userID = UserID()
			userID.name = (pgpKey.users.objectAtIndex(i) as! PGPUser).userID
			userID.toKey = newKey
			userID.emailAddress = ""
			userID.comment = ""
			userIDs.append(userID)
		}
		newKey.userIDs = NSSet(array: userIDs)
		newKey.subKeys = NSSet()
		newKey.keyData = pgp.exportKey(pgpKey, armored: true)
*/
		return newKey
	}
	
	private func getAlgorithmString(value: Int) -> String {
		switch value {
			case 1: return "RSA"
			case 2: return "RSA Encryption only"
			case 3: return "RSA Sign only"
			case 16: return "Elgamal"
			case 17: return "DSA"
			case 18: return "Elliptic"
			case 19: return "ECDSA"
			case 20: return "Elgamal EncryptorSign"
			case 21: return "Diffie Hellman"
			default: return "Private"
		}
	}
	
	private func saveKeyToCoreData(keyToSave: Key) -> Bool {
		var error: NSError?
		if self.managedObjectContext != nil {
			var newKeyEntry = NSEntityDescription.insertNewObjectForEntityForName("Key", inManagedObjectContext: self.managedObjectContext!) as! Key
			
			newKeyEntry.setValue(keyToSave.userIDprimary, forKey: "userIDprimary")
			newKeyEntry.setValue(keyToSave.emailAddressPrimary, forKey: "emailAddressPrimary")
			newKeyEntry.setValue(keyToSave.keyID, forKey: "keyID")
			newKeyEntry.setValue(keyToSave.isSecretKey, forKey: "isSecretKey")
			newKeyEntry.setValue(keyToSave.isPublicKey, forKey: "isPublicKey")
			newKeyEntry.setValue(keyToSave.created, forKey: "created")
			newKeyEntry.setValue(keyToSave.validThru, forKey: "validThru")
			newKeyEntry.setValue(keyToSave.keyLength, forKey: "keyLength")
			newKeyEntry.setValue(keyToSave.algorithm, forKey: "algorithm")
			newKeyEntry.setValue(keyToSave.fingerprint, forKey: "fingerprint")
			newKeyEntry.setValue(keyToSave.trust, forKey: "trust")
			newKeyEntry.setValue(keyToSave.userIDs, forKey: "userIDs")
			newKeyEntry.setValue(keyToSave.subKeys, forKey: "subKeys")
			newKeyEntry.setValue(keyToSave.keyData, forKey: "keyData")
			
			self.managedObjectContext!.save(&error)
		}
			
		
		if error != nil {
			NSLog("Error saving to CoreData: \(error?.localizedDescription)")
			return false
		} else {
			return true
		}
	}
	

}
