//
//  NavigationBarController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class NavigationBarController: NSViewController {
    private var topLevels: NSArray?;

    @IBOutlet public weak var outlineView: NSOutlineView?;

    public override func loadView() {
        topLevels = self.injectNib("NavigationBarController");

        if let ov = outlineView {
            ov.registerForDraggedTypes(["public.utf8.plain-text"]);
            ov.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal:true);
            ov.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal:false);
        }
    }
}
