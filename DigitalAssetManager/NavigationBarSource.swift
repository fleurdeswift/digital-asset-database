//
//  NavigationBarSource.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public let CategoryFavorites = "5aa5c2e0971046cba57610c20d296d459210a3d7f241dd3a70b562933de292bd";
public let CategorySpecial = "e5c08216588a2b08c48fcd78b646616e84ecfd485cd7343d869ae4cf624520b7";

@objc
public class NavigationBarSource : NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    public class Item : CustomStringConvertible {
        public let id: String;
        
        public var description: String {
            get {
                return id;
            }
        }
        
        public init(id: String) {
            self.id = id;
        }
    }

    public class Category : Item {
        public var items = [Item]();
    
        public init(id: String, items: [Item]) {
            super.init(id: id);
            self.items = items;
        }
    
        public override var description: String {
            get {
                if (id == CategoryFavorites) {
                    return NSLocalizedString("Favorites", comment: "Favorites in the navigation bar");
                }
                else if (id == CategorySpecial) {
                    return NSLocalizedString("Special", comment: "Specials in the navigation bar");
                }
                
                return super.description;
            }
        }
    }

    public class SavedSearch : CustomStringConvertible {
        public var description: String {
            get {
                return NSLocalizedString("Devices", comment: "Favorites in the navigation bar");
            }
        }
    }
    
    public let categories: [Category] = [
        Category(id: CategoryFavorites, items: [
            Item(id: "Newly added")
        ]),
        Category(id: CategorySpecial, items: [
            Item(id: "Drop box")
        ])
    ];
    
    public func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let item = item as? Category {
            return item.items.count;
        }
        
        return categories.count;
    }
    
    public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let item = item as? Category {
            return item.items[index];
        }
        else {
            return categories[index];
        }
    }
    
    public func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return item is Category;
    }
    
    public func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return item is Category;
    }
    
    public func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        return !(item is Category);
    }
    
    public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if let category = item as? Category {
            if let headerCell = outlineView.makeViewWithIdentifier("HeaderCell", owner:self) as? NSTableCellView {
                headerCell.textField!.stringValue = category.description;
                return headerCell;
            }
            
        }

        if let item = item as? Item {
            if let tableColumn = tableColumn {
                if let dataCell = outlineView.makeViewWithIdentifier("DataCell", owner:self) as? NSTableCellView {
                    dataCell.textField!.stringValue = item.description;
                    return dataCell;
                }
                return outlineView.makeViewWithIdentifier(tableColumn.identifier, owner:self);
            }
        }
        
        return nil;
    }
}
