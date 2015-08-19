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

public let DAMFileDropped = "DAMFileDropped";

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
    private(set) public var database: Database!;

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
            database.addDelegate(LibraryDatabaseBridge(library: self), strong: true)
        }
    }

    public override func makeWindowControllers() {
        let notificationCenter = NSNotificationCenter.defaultCenter();

        notificationCenter.addObserver(self, selector: Selector("fileDropped:"), name: DAMFileDropped, object: nil);

        let storyboard       = NSStoryboard(name: "Library", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Library Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    @objc
    public func fileDropped(notification: NSNotification) {
        if let windowController = self.windowControllers.first {
            if let urls: [NSURL] = notification.userInfo?["urls"] as? [NSURL] {
                if let sheet = ImportFiles(library: self, urls: urls), contentViewController = windowController.contentViewController {
                    contentViewController.presentViewControllerAsSheet(sheet)
                }
            }
        }
    }

    public func urlFor(titleInstance titleInstance: String, create: Bool) -> NSURL {
        let url = storageURL!.URLByAppendingPathComponent(titleInstance, isDirectory: true);

        if create {
            if let path = url.path {
                Darwin.mkdir(path, 0o755);
            }
        }

        return url;
    }

    public func urlFor(titleInstance: TitleInstance) -> NSURL {
        return urlFor(titleInstance: titleInstance.id, create: false);
    }

    public func urlFor(titleInstance: TitleInstance, create: Bool) -> NSURL {
        return urlFor(titleInstance: titleInstance.id, create: create);
    }
}
