//
//  TagSource.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase
import ExtraAppKit

@objc
public class TagSource : NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate, FilterablePredicateGenerator {
    public weak var library: Library? {
        didSet {
            if let database = library?.database {
                for category in categories {
                    database.findTags(type: category.type) { (tags: [Tag]) -> Void in
                        dispatch_async(dispatch_get_main_queue()) {
                            self.loadCategory(category, tags: tags)
                        }
                    }
                }
            }
        }
    }
    
    public class Category : CustomStringConvertible {
        public let type: TagType;
        public var items = [Tag]();
    
        public init(_ type: TagType) {
            self.type = type;
        }
    
        public var description: String {
            get {
                return type.localizedName;
            }
        }
    }
    
    public let categories: [Category] = [
        Category(TagType.Favorites),
        Category(TagType.Recents),
        Category(TagType.Action),
        Category(TagType.Nationality),
        Category(TagType.Set),
        Category(TagType.Person),
        Category(TagType.Rating),
        Category(TagType.Serie),
    ]

    public func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            return categories.count;
        }
        else if let category = item as? Category {
            return category.items.count;
        }
        
        return 0;
    }
    
    public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            return categories[index];
        }
        else if let category = item as? Category {
            return category.items[index];
        }
        
        return NSNull();
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

        if let tag = item as? Tag {
            if let dataCell = outlineView.makeViewWithIdentifier("DataCell", owner:self) as? NSTableCellView {
                dataCell.textField!.stringValue = tag.name;
                return dataCell;
            }
        }
        
        return nil;
    }
    
    private func loadCategory(category: Category, tags: [Tag]) {
        category.items = tags;
    }
    
    public func generatePredicateFromString(string: String?) -> PredicateBlockType? {
        if let searchString = string {
            let lower = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lowercaseString
        
            if lower.characters.count == 0 {
                return nil;
            }
        
            return { (item: AnyObject) -> Bool in
                if let tag  = item as? Tag {
                    return tag.name.lowercaseString.rangeOfString(lower) != nil;
                }
                
                return false;
            }
        }
    
        return nil;
    }
}
