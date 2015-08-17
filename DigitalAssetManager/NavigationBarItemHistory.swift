//
//  NavigationBarItemHistory.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public let NavigationBarItemLogicalPasteboardType = "com.fds.sidebar.item.logical";
public let PlainTextPasteboardType = "public.utf8-plain-text";

public class NavigationBarItemHistory : NavigationBarItem, NSPasteboardWriting {
    public override var description: String {
        get {
            return "History";
        }
    }

    public override var icon: NSImage {
        get {
            return NSImage(named: "History")!;
        }
    }

    public func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        return [NavigationBarItemLogicalPasteboardType, PlainTextPasteboardType];
    }

    public func pasteboardPropertyListForType(type: String) -> AnyObject? {
        if type == NavigationBarItemLogicalPasteboardType {
            return "0e769600933790607b2a13b33ddfade0fa17810eb62c3b28ee23e59516516491";
        }
        else if type == PlainTextPasteboardType {
            return self.description;
        }

        return nil;
    }
}
