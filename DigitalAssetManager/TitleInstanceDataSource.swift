//
//  TitleInstanceDataSource.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase

public class TitleInstanceDataSource : NSObject, NSTableViewDataSource {
    public var titleInstances: [TitleInstance] = [];

    public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return titleInstances.count;
    }

    public func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return titleInstances[row];
    }
}

private var TitleInstanceDelegateCachedHeight: CGFloat?;

public class TitleInstanceDelegate : NSObject, NSTableViewDelegate {
    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeViewWithIdentifier("TitleInstance", owner: self) as! TitleInstanceCellView;

        view.titleInstance = tableView.dataSource()?.tableView?(tableView, objectValueForTableColumn: tableColumn, row: row) as? TitleInstance;
        return view;
    }

    public func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cached = TitleInstanceDelegateCachedHeight {
            return cached;
        }
        else if let view = tableView.makeViewWithIdentifier("TitleInstance", owner: self) as? NSTableCellView {
            TitleInstanceDelegateCachedHeight = view.bounds.height;
            return TitleInstanceDelegateCachedHeight!;
        }
        else {
            return 100;
        }
    }
}
