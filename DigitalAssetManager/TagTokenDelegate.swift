//
//  TagTokenDelegate.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase
import ExtraDataStructures
import SQL

public class TagTokenDelegate : NSObject, NSTokenFieldDelegate {
    private let database: Database;
    private var tags       = [Tag]();
    private let queue      = dispatch_queue_create("TagTokenDelegate", DISPATCH_QUEUE_SERIAL);
    private let uncommited = NSMapTable.strongToWeakObjectsMapTable();

    public init(library: Library) {
        self.database = library.database;
        super.init();

        database.handle.readAsync { (access: SQLRead) throws -> Void in
            let tags = self.database.tags(access);

            dispatch_async_main {
                self.setTags(tags);
            }
        }

        let center = NSNotificationCenter.defaultCenter();
        center.addObserver(self, selector: Selector("tagAdded:"),       name: DADTagAddedNotification,       object: library);
        center.addObserver(self, selector: Selector("tagNameChanged:"), name: DADTagNameChangedNotification, object: library);
    }

    @objc
    private func tagAdded(notification: NSNotification) {
        let tag  = notification.userInfo?["Tag"] as! Tag;

        dispatch_async(queue) {
            var copy = self.tags;
            copy.append(tag);
            copy.sortInPlace { return $0.name ^< $1.name }

            dispatch_sync_main {
                self.tags = copy;
            }
        }
    }

    @objc
    private func tagNameChanged(notification: NSNotification) {
        dispatch_async(queue) {
            var copy = self.tags;
            copy.sortInPlace { return $0.name ^< $1.name }

            dispatch_sync_main {
                self.tags = copy;
            }
        }
    }

    private func setTags(tags: [Tag]) {
        self.tags = tags;
    }

    public func tokenField(tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [AnyObject]? {
        let filtered = self.tags.filter { $0.name.containsSubstringCI(substring) }

        if let indexOf = filtered.indexOf({ $0.name.hasPrefix(substring) }) {
            selectedIndex.memory = indexOf;
        }

        return filtered.map { return $0.name };
    }

    public func tokenField(tokenField: NSTokenField, displayStringForRepresentedObject representedObject: AnyObject) -> String? {
        if let describable = representedObject as? CustomStringConvertible {
            return describable.description;
        }

        return nil;
    }

    public func tokenField(tokenField: NSTokenField, editingStringForRepresentedObject representedObject: AnyObject) -> String? {
        if let describable = representedObject as? CustomStringConvertible {
            return describable.description;
        }

        return nil;
    }

    public func tokenField(tokenField: NSTokenField, representedObjectForEditingString editingString: String) -> AnyObject {
        let str = editingString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
        if str.characters.count == 0 {
            return String();
        }

        if let index = tags.indexOf({ $0.name ^== str }) {
            return tags[index];
        }

        return str;
    }

    public func tokenField(tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: AnyObject) -> Bool {
        return false;
    }
}

public extension String {
    public func containsSubstringCI(str: String) -> Bool {
        return self.rangeOfString(str, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil;
    }
}


