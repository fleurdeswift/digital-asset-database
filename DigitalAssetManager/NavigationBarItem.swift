//
//  NavigationBarItem.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class NavigationBarItem : NSObject, NSCoding {
    public override init() {
    }

    public required init?(coder decoder: NSCoder) {
    }

    public func encodeWithCoder(coder: NSCoder) {
    }

    public func createViewControllerforItem() -> NSViewController? {
        return nil;
    }

    public var icon : NSImage {
        get {
            return NSImage(named: "NSActionTemplate")!;
        }
    }

    public override var description: String {
        get {
            return self.className;
        }
    }
}
