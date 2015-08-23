//
//  WorkAreaView.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

/// This view is basically a view is the socket for a content view. It isolate the layout of it and make the
/// resizability of the view.
@IBDesignable
public class WorkAreaView : NSView {
    @IBInspectable public dynamic var backgroundColor: NSColor = NSColor(genericGamma22White: 0.2, alpha: 1.0) {
        didSet {
            self.needsDisplay = true;
        }
    }

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
            v.setFrameSize(size);
        }
    }

    public override func drawRect(dirtyRect: NSRect) {
        backgroundColor.setFill();
        NSRectFill(dirtyRect);
    }

    public weak var contentView: NSView? {
        willSet {
            if let oldView = contentView {
                oldView.removeFromSuperviewWithoutNeedingDisplay()
            }

            if let newView = newValue {
                newView.autoresizingMask = NSAutoresizingMaskOptions.ViewNotSizable;
                newView.translatesAutoresizingMaskIntoConstraints = true;
                newView.frame = self.bounds;
                self.addSubview(newView);
            }
        }
    }
}
