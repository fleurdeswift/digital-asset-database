//
//  BlankAreaViewController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class BlankAreaViewController: NSViewController {
    public class func create() -> BlankAreaViewController {
        return BlankAreaViewController(nibName: "BlankAreaViewController", bundle: nil)!;
    }
}
