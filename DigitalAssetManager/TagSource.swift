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
        
        public func sort() {
            items.sortInPlace { return $0.name ^< $1.name; }
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

    public func outlineView(outlineView: NSOutlineView, tagNameChanged tag: Tag) {
        if let index = categories.indexOf({ return $0.type.rawValue == tag.type }) {
            let category = categories[index];
            
            if let oldIndex = category.items.indexOf(tag) {
                category.sort();
                
                if let newIndex = category.items.indexOf(tag) {
                    outlineView.beginUpdates();
                    outlineView.moveItemAtIndex(oldIndex, inParent: category, toIndex: newIndex, inParent: category);
                    outlineView.endUpdates();
                }
            }
        }
        outlineView.reloadItem(tag);
    }

    public func outlineView(outlineView: NSOutlineView, tagTypeChanged tag: Tag, oldType: TagType) {
        if let oldCategoryIndex = categories.indexOf({ return $0.type == oldType }),
           let newCategoryIndex = categories.indexOf({ return $0.type.rawValue == tag.type }) {
            let oldCategory = categories[oldCategoryIndex];
            let newCategory = categories[newCategoryIndex];

            if let oldIndex = oldCategory.items.indexOf(tag) {
                newCategory.items.append(tag);
                newCategory.sort();
                
                if let newIndex = newCategory.items.indexOf(tag) {
                    outlineView.beginUpdates();
                    outlineView.moveItemAtIndex(oldIndex, inParent: oldCategory, toIndex: newIndex, inParent: newCategory);
                    outlineView.endUpdates();
                }
            }
        }
    }
    
    public func outlineView(outlineView: NSOutlineView, tagAdded tag: Tag) {
        if let index = categories.indexOf({ return $0.type.rawValue == tag.type }) {
            let category = categories[index];
            
            category.items.append(tag);
            category.sort()
            
            if let itemIndex = category.items.indexOf({ return $0 === tag }) {
                outlineView.beginUpdates();
                outlineView.insertItemsAtIndexes(NSIndexSet(index: itemIndex), inParent: category, withAnimation: NSTableViewAnimationOptions.SlideDown);
                outlineView.endUpdates();
            }
        }
    }

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

    public func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
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
            if let dataCell = outlineView.makeViewWithIdentifier("DataCell", owner:self) as? TagCellView {
                dataCell.representedTag = tag;
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
