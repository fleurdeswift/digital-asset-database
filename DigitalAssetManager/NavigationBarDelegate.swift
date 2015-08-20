//
//  NavigationBarDelegate.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public let NavigationBarSelectionChanged = "NavigationBarSelectionChanged";

@objc
public class NavigationBarDelegate : NSObject, NSOutlineViewDelegate {
    public func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return item is NavigationBarGroup;
    }

    public func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        return !(item is NavigationBarGroup);
    }

    public func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if let group = item as? NavigationBarGroup {
            if let headerCell = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as? NSTableCellView {
                headerCell.textField!.stringValue = group.description;
                headerCell.needsLayout = true;
                return headerCell;
            }
        }

        if let item = item as? NavigationBarItem {
            if let tableColumn = tableColumn {
                if let dataCell = outlineView.makeViewWithIdentifier("DataCell", owner: self) as? NSTableCellView {
                    dataCell.textField!.stringValue = item.description;
                    dataCell.imageView!.image = item.icon;
                    return dataCell;
                }
                return outlineView.makeViewWithIdentifier(tableColumn.identifier, owner: self);
            }
        }
        
        return nil;
    }

    private var itemHeight:  CGFloat?;
    private var groupHeight: CGFloat?;

    public func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        if let item = item as? NavigationBarGroup {
            if let height = groupHeight {
                return height;
            }

            if let view = self.outlineView(outlineView, viewForTableColumn: nil, item: item) {
                groupHeight = max(8, view.fittingSize.height);
                return groupHeight!;
            }
        }

        if let item = item as? NavigationBarItem {
            if let height = itemHeight {
                return height;
            }

            if let view = self.outlineView(outlineView, viewForTableColumn: nil, item: item) {
                itemHeight = max(8, view.fittingSize.height);
                return itemHeight!;
            }
        }

        return 17;
    }

    public func outlineViewSelectionDidChange(notification: NSNotification) {
        if let outlineView = notification.object as? NSOutlineView {
            if let item = outlineView.itemAtRow(outlineView.selectedRow) as? NavigationBarItem {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(NavigationBarSelectionChanged, object: outlineView.window!, userInfo: [
                        "Item": item
                    ]);
                }
            }
        }
    }
}
