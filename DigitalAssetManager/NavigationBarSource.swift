//
//  NavigationBarSource.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

@objc
public class NavigationBarSource : NSObject, NSOutlineViewDataSource {
    internal var root: NavigationBarItemRoot;

    public override init() {
        root = NavigationBarItemRoot(childs: [NavigationBarGroupStandard()]);
        super.init();
    }

    public func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item != nil {
            if let group = item as? NavigationBarGroup {
                return group.childs.count;
            }

            return 0;
        }
        
        return root.childs.count;
    }
    
    public func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item != nil {
            if let group = item as? NavigationBarGroup {
                return group.childs[index];
            }

            assert(false);
        }
        
        return root.childs[index];
    }
    
    public func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return item is NavigationBarGroup;
    }
    
    public func outlineView(outlineView: NSOutlineView, pasteboardWriterForItem item: AnyObject) -> NSPasteboardWriting? {
        return item as? NSPasteboardWriting;
    }

    public func outlineView(outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: AnyObject?, proposedChildIndex index: Int) -> NSDragOperation {
       return NSDragOperation.Generic;
    }

    public func outlineView(outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forItems draggedItems: [AnyObject]) {
        session.draggingPasteboard.setData(NSData(), forType:PlainTextPasteboardType);
        outlineView.draggingDestinationFeedbackStyle = NSTableViewDraggingDestinationFeedbackStyle.Gap;
    }

    public func outlineView(outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
    }

    public func outlineView(outlineView: NSOutlineView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
    }
}
