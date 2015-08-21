//
//  TagPaneController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import ExtraAppKit
import DigitalAssetDatabase

private let types: [TagType] = [
    TagType.Action,
    TagType.Set,
    TagType.Serie,
    TagType.Rating,
    TagType.Person,
    TagType.Nationality
]

public class TagPaneController : NSViewController {
    private var topLevels: NSArray?;
    private weak var library: Library?;
    
    @IBOutlet private weak var addTagName:  NSTextField?;
    @IBOutlet private weak var addTagType:  NSPopUpButton?;
    @IBOutlet private weak var addTagSheet: NSWindow?;
    
    @IBOutlet private weak var tagView:   FilterableOutlineView?;
    @IBOutlet private weak var tagSource: TagSource?;
    
    public override func loadView() {
        topLevels = self.injectNib("TagPane");
    }
    
    public override func viewWillAppear() {
        library = self.view.window?.windowController?.document as? Library;
        tagSource?.library = library;
        
        if let addTagType = addTagType {
            for type in types.sort({ return $0.localizedName ^< $1.localizedName; }) {
                addTagType.addItemWithTitle(type.localizedName, representedObject: type.rawValue);
            }
        }
        
        if let library = library {
            let center = NSNotificationCenter.defaultCenter();
            center.addObserver(self, selector: Selector("tagAdded:"),       name: DADTagAddedNotification,       object: library);
            center.addObserver(self, selector: Selector("tagNameChanged:"), name: DADTagNameChangedNotification, object: library);
            center.addObserver(self, selector: Selector("tagTypeChanged:"), name: DADTagTypeChangedNotification, object: library);
        }
    }
    
    @objc
    private func tagAdded(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            tagSource?.outlineView(tagView!, tagAdded: userInfo["Tag"] as! Tag);
        }
    }

    @objc
    private func tagNameChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            tagSource?.outlineView(tagView!, tagNameChanged: userInfo["Tag"] as! Tag);
        }
    }

    @objc
    private func tagTypeChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            tagSource?.outlineView(tagView!, tagTypeChanged: userInfo["Tag"] as! Tag, oldType: TagType(rawValue: userInfo["OldType"] as! String)!);
        }
    }
        
    @IBAction
    public func addTag(sender: AnyObject?) {/*
        if let sheet = addTagSheet {
            addTagName?.stringValue = "";
            self.view.window?.beginSheet(sheet) { (response: NSModalResponse) in
                if response != 0 {
                    return;
                }
            
                if let library = self.library, let newTagName = self.addTagName?.stringValue, let item = self.addTagType?.selectedItem {
                    do {
                        try library.database?.addTag(newTagName, type: TagType(rawValue: item.representedObject as! String)!);
                    }
                    catch {
                    }
                }
            }
        }*/
    }
    
    @IBAction
    public func cancelAddTag(sender: AnyObject?) {
        if let sheet = addTagSheet {
            self.view.window?.endSheet(sheet, returnCode: -1)
        }
    }

    @IBAction
    public func performAddTag(sender: AnyObject?) {
        if let sheet = addTagSheet {
            self.view.window?.endSheet(sheet, returnCode: 0)
        }
    }
}
