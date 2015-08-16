//
//  Library.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase;

public let DADTagAddedNotification        = "DADTagAdded";
public let DADTagNameChangedNotification  = "DADTagNameChanged";
public let DADTagTypeChangedNotification  = "DADTagTypeChanged";

public extension NSNotificationCenter {
    public class func postAsync(name: String, object: NSObject?, userInfo: [String: AnyObject]) {
        dispatch_async(dispatch_get_main_queue()) {
            self.defaultCenter().postNotificationName(name, object: object, userInfo: userInfo);
        }
    }
}

private class LibraryDatabaseBridge : DatabaseDelegate {
    private weak var library: Library?;

    init(library: Library) {
        self.library = library;
    }

    func dispatchNotification(name: String, forTag tag: Tag) {
        if let library = library {
            NSNotificationCenter.postAsync(name, object: library, userInfo: [
                "Tag": tag
            ])
        }
    }

    func tagAdded(tag: Tag) {
        dispatchNotification(DADTagAddedNotification, forTag: tag);
    }
    
    func tagNameChanged(tag: Tag) {
        dispatchNotification(DADTagNameChangedNotification, forTag: tag);
    }
    
    func tagTypeChanged(tag: Tag, oldType: String) {
        if let library = library {
            NSNotificationCenter.postAsync(DADTagTypeChangedNotification, object: library, userInfo: [
                "Tag":     tag,
                "OldType": oldType
            ])
        }
    }
}

public class Library : NSDocument {
    private var format = NSPropertyListFormat.XMLFormat_v1_0;
    private var databaseURL: NSURL?;
    private var storageURL:  NSURL?;
    private(set) public var database: Database?;

    public override func readFromURL(url: NSURL, ofType typeName: String) throws {
        let data  = try NSData(contentsOfURL: url, options: NSDataReadingOptions());
        let plist = try NSPropertyListSerialization.propertyListWithData(data,
                            options: NSPropertyListReadOptions.MutableContainersAndLeaves,
                            format:  &format)
        
        if let dict = plist as? NSDictionary {
            let config: [String: AnyObject] = dict as! Dictionary;
            
            databaseURL = NSURL(string: config["DatabaseURL"] as! String, relativeToURL: url);
            storageURL  = NSURL(string: config["StorageURL"]  as! String, relativeToURL: url);
            database    = try Database(path: databaseURL!.absoluteString);
            database?.addDelegate(LibraryDatabaseBridge(library: self), strong: true)
        }
    }

    public override func makeWindowControllers() {
        let storyboard       = NSStoryboard(name: "Library", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Library Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }
}
