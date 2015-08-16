//
//  NavigationBarItemRoot.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class NavigationBarItemRoot : NavigationBarGroup {
    internal(set) public var items: [AnyObject];

    public init(childs: [AnyObject]) {
        self.items = childs;
        super.init();
    }

    public required init?(coder decoder: NSCoder) {
        if let items = decoder.decodeObjectForKey("childs") as? [AnyObject] {
            self.items = items;
        }
        else {
            self.items = [AnyObject]();
        }

        super.init(coder: decoder);
    }

    public override var childs: [AnyObject] {
        get {
            return items;
        }
    }

    public override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder);
        coder.encodeObject(items, forKey: "childs");
    }
}
