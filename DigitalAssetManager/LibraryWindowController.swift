//
//  LibraryWindowController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public extension NSView {
    public func enumerateSubviews(@noescape block: (NSView) -> Bool) -> Bool {
        for child in self.subviews {
            if block(child) {
                return true;
            }

            if child.enumerateSubviews(block) {
                return true;
            }
        }

        return false;
    }
}

public extension NSViewController {
    public func enumerateViewControllers(@noescape block: (NSViewController) -> Bool) -> Bool {
        for child in self.childViewControllers {
            if block(child) {
                return true;
            }

            if child.enumerateViewControllers(block) {
                return true;
            }
        }

        return false;
    }
}

public class LibraryWindowController : NSWindowController {
    public weak var workArea: WorkAreaView!;
    public weak var workAreaViewController: WorkAreaViewController!;

    public override func awakeFromNib() {
        self.contentViewController?.enumerateViewControllers { (view: NSViewController) -> Bool in
            if let workArea = view as? WorkAreaViewController {
                self.workAreaViewController = workArea;
                return true;
            }

            return false;
        }

        if let window = self.window {
            window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
            window.contentView?.enumerateSubviews { (view: NSView) -> Bool in
                if let workArea = view as? WorkAreaView {
                    self.workArea = workArea;
                    return true;
                }

                return false;
            }
        }

        let notificationCenter = NSNotificationCenter.defaultCenter();

        notificationCenter.addObserver(self, selector: Selector("navigationBarSelectionChanged:"), name: NavigationBarSelectionChanged, object: self.window);
    }

    @objc
    public func navigationBarSelectionChanged(notification: NSNotification) {
        if let item = notification.userInfo?["Item"] as? NavigationBarItem {
            workAreaViewController.navigateTo(item);
        }
    }
}
