//
//  WorkAreaViewController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class WorkAreaViewControllerDelegate : NSObject, NSPageControllerDelegate {
    public func pageController(pageController: NSPageController, identifierForObject object: AnyObject) -> String {
        if let _ = object as? NavigationBarItemDropBox {
            return "ResultView";
        }

        return "BlankArea";
    }
    
    public func pageController(pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        if identifier == "ResultView" {
            return ResultViewController.create();
        }

        return BlankAreaViewController.create();
    }

    public func pageController(pageController: NSPageController, prepareViewController viewController: NSViewController, withObject object: AnyObject) {
    }
};

public extension NSView {
    public func addFillContraintsForChild(otherView: NSView) {
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top,      relatedBy: NSLayoutRelation.Equal, toItem: otherView, attribute: NSLayoutAttribute.Top,      multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Leading,  relatedBy: NSLayoutRelation.Equal, toItem: otherView, attribute: NSLayoutAttribute.Leading,  multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Bottom,   relatedBy: NSLayoutRelation.Equal, toItem: otherView, attribute: NSLayoutAttribute.Bottom,   multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: otherView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
    }
}

public class WorkAreaViewController : NSViewController {
    private var currentObject: AnyObject?;
    private var currentViewController: NSViewController?;
    private let pageController = NSPageController();

    public var delegate = WorkAreaViewControllerDelegate();

    public func navigateTo(item: AnyObject) {
        if (currentObject === item) {
            return;
        }

        currentObject = item;

        let identifier = delegate.pageController(pageController, identifierForObject: item);
        let controller = delegate.pageController(pageController, viewControllerForIdentifier: identifier);

        delegate.pageController(pageController, prepareViewController: controller, withObject: item)

        self.addChildViewController(controller)

        if let oldController = self.currentViewController {
            oldController.removeFromParentViewController();
        }

        (self.view as? WorkAreaView)?.contentView = controller.view;
        self.currentViewController = controller;
    }
}
