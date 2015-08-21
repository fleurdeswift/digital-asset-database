//
//  ResultViewController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class ResultViewController: NSViewController {
    @IBOutlet
    public weak var tableView: NSTableView!;

    @IBOutlet
    public weak var titleInstances: TitleInstanceDataSource!;

    public class func create() -> ResultViewController {
        return ResultViewController(nibName:"ResultViewController", bundle: NSBundle.mainBundle())!;
    }

    public override func loadView() {
        super.loadView();
        tableView.registerNib(NSNib(nibNamed: "TitleInstance", bundle: nil), forIdentifier: "TitleInstance");
    }
}
