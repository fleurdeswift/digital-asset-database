//
//  NavigationBarGroup.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class NavigationBarGroup : NSObject, NSCoding {
    public var childs: [AnyObject] {
        get {
            return [AnyObject]();
        }
    }

    public override init() {
    }

    public required init?(coder decoder: NSCoder) {
    }

    public func encodeWithCoder(coder: NSCoder) {
    }

    public func canInsertItem(item: AnyObject, asIndex: Int) -> Bool {
        return false;
    }
}
