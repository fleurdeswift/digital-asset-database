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
    TagType.Set
]

public class TagPaneController : NSViewController {
    private var topLevels: NSArray?;
    
    @IBOutlet private weak var addTagName:  NSTextField?;
    @IBOutlet private weak var addTagType:  NSPopUpButton?;
    @IBOutlet private weak var addTagSheet: NSWindow?;
    
    @IBOutlet private weak var tagView:   FilterableDataSource?;
    @IBOutlet private weak var tagSource: TagSource?;
    
    public override func loadView() {
        topLevels = self.injectNib("TagPane");
    }
    
    public override func viewWillAppear() {
        if let library = self.view.window?.windowController?.document as? Library {
            tagSource?.library = library;
        }
        
        if let addTagType = addTagType {
            for type in types {
                addTagType.addItemWithTitle(type.localizedName);
            }
        }
    }
    
    @IBAction
    public func addTag(sender: AnyObject?) {
        if let sheet = addTagSheet {
            addTagName?.stringValue = "";
            self.view.window?.beginSheet(sheet) { (response: NSModalResponse) in
                sheet.description;
            }
        }
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
