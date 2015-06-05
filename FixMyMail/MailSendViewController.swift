import UIKit
import CoreData
import AddressBook
import Foundation

class MailSendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var sendTableView: UITableView!
    
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var tvText: UITextView!
    @IBOutlet weak var Suggestion: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellSubject", bundle: nil), forCellReuseIdentifier: "SendViewCellSubject")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellSuggestion", bundle: nil), forCellReuseIdentifier: "SendViewCellSuggestion")
        self.sendTableView.rowHeight = UITableViewAutomaticDimension
        self.sendTableView.estimatedRowHeight = 100
        self.sendTableView.scrollEnabled = false
        var sendBut: UIBarButtonItem = UIBarButtonItem(title: "Senden", style: .Plain, target: self, action: "butSend:")
        self.navigationItem.rightBarButtonItem = sendBut
        LoadAddresses()
    }
    
    
    @IBAction func butSend(sender: AnyObject) {
        var managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                let acc: EmailAccount = emailAccounts[0] as! EmailAccount
                
                var session = MCOSMTPSession()
                session.hostname = acc.smtpHostname
                session.port = acc.smtpPort
                session.username = acc.username
                session.password = acc.password
                session.connectionType = MCOConnectionType.TLS;
                session.authType = MCOAuthType.SASLPlain;
                
                var builder = MCOMessageBuilder()
                var from = MCOAddress()
                from.displayName = "Fix Me"
                from.mailbox = acc.emailAddress
                var sender = MCOAddress()
                sender.displayName = "Fix Me"
                sender.mailbox = acc.emailAddress
                builder.header.from = from
                builder.header.sender = sender
                var tos : NSMutableArray = NSMutableArray()
                var toCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SendViewCellSuggestion
                var recipients: String = toCell.txtTo.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                for recipient in recipients.componentsSeparatedByString(", ") {
                    var to = MCOAddress()
                    to.mailbox = recipient
                    NSLog("%@", recipient)
                    tos.addObject(to)
                }
                builder.header.to = tos as [AnyObject]
                var subCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SendViewCellSubject
                builder.header.subject = subCell.txtText.text
                builder.textBody = tvText.text
                
                let op = session.sendOperationWithData(builder.data())
                
                op.start({(NSError error) in
                    if (error != nil) {
                        NSLog("can't send message: %@", error)
                    } else {
                        toCell.txtTo.text = ""
                        subCell.txtText.text = ""
                        self.tvText.text = ""
                        NSLog("sent")
                    }
                })
            }
        }
        
    }
    
    // TableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellSuggestion", forIndexPath: indexPath) as! SendViewCellSuggestion
            sendCell.emails = sortedEmails
            return sendCell
        case 1:
            var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellSubject", forIndexPath: indexPath) as! SendViewCellSubject
            return sendCell
        default:
            var sendCell = UITableViewCell()
            return sendCell
        }
    }
    
    
    
    // Addressbook functionality
    var allEmail: NSMutableArray = []
    var sortedEmails: NSArray = []
    func addRecord(Entry: Record){
        allEmail.addObject(Entry)
    }
    func orderEmails(){
        var allEmailIDs:NSArray = allEmail
        println("ordering")
        let descriptor = NSSortDescriptor(key: "email", ascending: true, selector: "localizedStandardCompare:")
        var sortedResults: NSArray = allEmail.sortedArrayUsingDescriptors([descriptor])
        for results in sortedResults {
            println ("contactEmail : \(results.email as String)")
        }
        
        sortedEmails = sortedResults
    }
    
    func LoadAddresses() {
        
        //var contactList: NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
        var source: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
        var contactList: NSArray = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, ABPersonSortOrdering(kABPersonEmailProperty )).takeRetainedValue()
        
        println("records in the array \(contactList.count)")
        
        for record:ABRecordRef in contactList{
            if !record.isEqual(nil){
                var contactPerson: ABRecordRef = record
                
                let emailProperty: ABMultiValueRef = ABRecordCopyValue(record, kABPersonEmailProperty).takeRetainedValue() as ABMultiValueRef
                if ABMultiValueGetCount(emailProperty) > 0 {
                    let allEmailIDs : NSArray = ABMultiValueCopyArrayOfAllValues(emailProperty).takeUnretainedValue() as NSArray
                    for email in allEmailIDs {
                        let emailID = email as! String
                        let contactFirstName: String = ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty)?.takeRetainedValue() as? String ?? ""
                        let contactLastName: String = ABRecordCopyValue(contactPerson, kABPersonLastNameProperty)?.takeRetainedValue() as? String ?? ""
                        addRecord(Record(firstname:contactFirstName, lastname: contactLastName, email:emailID as String))
                        println ("contactEmail : \(emailID) :=>")
                    }
                }
            }
        }
        orderEmails()
    }
}

class Record: NSObject{
    let email: String
    let lastname: String
    let firstname: String
    
    init ( firstname: String, lastname: String, email: String){
        self.email = email
        self.lastname = lastname
        self.firstname = firstname
    }
    
}