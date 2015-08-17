//
//  NavigationBarItemDropBox.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class NavigationBarItemDropBox : NavigationBarItem, NSPasteboardWriting {
    public override var description: String {
        get {
            return "Dropbox";
        }
    }

    public override var icon: NSImage {
        get {
            return NSImage(named: "Dropbox")!;
        }
    }

    public func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        return [NavigationBarItemLogicalPasteboardType, PlainTextPasteboardType];
    }

    public func pasteboardPropertyListForType(type: String) -> AnyObject? {
        if type == NavigationBarItemLogicalPasteboardType {
            return "9753d4438475ac2d6d620b6f7ccdb96f1ddef9d97e8a7c10872c5c93bd121e29";
        }
        else if type == PlainTextPasteboardType {
            return self.description;
        }

        return nil;
    }
}
