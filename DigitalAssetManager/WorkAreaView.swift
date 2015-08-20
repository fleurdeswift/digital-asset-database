//
//  WorkAreaView.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class WorkAreaView : NSView {
    public override var intrinsicContentSize: NSSize {
        get {
            return NSSize(width: 320, height: 200);
        }
    }

    public override var opaque: Bool {
        get {
            return true;
        }
    }

    public override func setFrameSize(size: NSSize) {
        super.setFrameSize(size);

        if let v = contentView {
            v.frame = self.bounds;
        }
    }

    public override func drawRect(dirtyRect: NSRect) {
        NSColor.blackColor().setFill();
        NSRectFill(dirtyRect);
    }

    public weak var contentView: NSView? {
        willSet {
            if let oldView = contentView {
                oldView.removeFromSuperviewWithoutNeedingDisplay()
            }

            if let newView = newValue {
                self.addSubview(newView);
                newView.frame = self.bounds;
            }
        }
    }
}
