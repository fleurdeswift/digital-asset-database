//
//  WorkAreaViewController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase
import ExtraDataStructures

public class WorkAreaViewControllerDelegate : NSObject, NSPageControllerDelegate {
    public weak var windowController: NSWindowController?;

    public var library: Library? {
        get {
            return windowController?.document as? Library;
        }
    }

    public var database: Database? {
        get {
            return self.library?.database;
        }
    }

    public func pageController(pageController: NSPageController, identifierForObject object: AnyObject) -> String {
        if let _ = object as? NavigationBarItemDropBox {
            return "ResultView";
        }
        else if let _ = object as? TitleInstance {
            return "AnnotationView"
        }

        return "BlankArea";
    }
    
    public func pageController(pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        if identifier == "ResultView" {
            return ResultViewController.create();
        }
        else if identifier == "AnnotationView" {
            return AnnotationViewController.create();
        }

        return BlankAreaViewController.create();
    }

    public func pageController(pageController: NSPageController, prepareViewController viewController: NSViewController, withObject object: AnyObject) {
        if let database = self.database {
            viewController.representedObject = [
                "database": database,
                "object":   object,
            ];
        }
    }
};

public class WorkAreaViewController : NSViewController {
    private var currentObject:         AnyObject?;
    private var currentViewController: NSViewController?;

    private let pageController = NSPageController();
    public  var delegate       = WorkAreaViewControllerDelegate();

    public override func viewDidAppear() {
        super.viewDidAppear();
        delegate.windowController = self.view.window?.windowController;
    }

    public override func viewDidDisappear() {
        super.viewDidDisappear();

        if let cvc = currentViewController {
            cvc.dismissController(self);
        }

        currentViewController = nil;
    }

    public func navigateTo(item: AnyObject) {
        if (currentObject === item) {
            return;
        }

        if let cvc = currentViewController {
            cvc.dismissController(self);
        }

        currentObject = item;

        let identifier = delegate.pageController(pageController, identifierForObject: item);
        let controller = delegate.pageController(pageController, viewControllerForIdentifier: identifier);

        delegate.pageController(pageController, prepareViewController: controller, withObject: item)

        self.addChildViewController(controller)

        if let oldController = self.currentViewController {
            oldController.removeFromParentViewController();
        }

        if let workAreaView = self.view as? WorkAreaView {
            workAreaView.contentView = controller.view;

            if controller.view.acceptsFirstResponder {
                workAreaView.window?.makeFirstResponder(controller.view);
            }
        }

        self.currentViewController = controller;
    }
}
