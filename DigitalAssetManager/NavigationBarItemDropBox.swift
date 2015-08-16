//
//  NavigationBarItemDropBox.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class NavigationBarItemDropBox : NavigationBarItem {
    public override var description: String {
        get {
            return "Dropbox";
        }
    }

    public override var icon: NSImage {
        get {
            return NSImage(named: "Dropbox")!;
        }
    }
}
