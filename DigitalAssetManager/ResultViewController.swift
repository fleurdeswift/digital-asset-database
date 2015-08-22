//
//  ResultViewController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase
import ExtraDataStructures

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

    public override var representedObject: AnyObject? {
        didSet {
            if let info = self.representedObject as? [String: AnyObject] {
                let object   = info["object"];
                let database = info["database"] as! Database;

                self.view.description
                let tableView  = self.tableView;
                let dataSource = tableView.dataSource() as! TitleInstanceDataSource;

                if let _ = object as? NavigationBarItemDropBox {
                    database.dropBox(1000) { (instances: [TitleInstance]) in
                        dispatch_async_main {
                            dataSource.titleInstances = instances;
                            tableView.reloadData();
                        }
                    }
                }
            }
        }
    }
}
