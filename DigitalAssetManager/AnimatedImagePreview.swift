//
//  AnimatedImagePreview.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class AnimatedImagePreview : NSView {
    public var urls = [NSURL]();

    public override func updateTrackingAreas() {
        let options = NSTrackingAreaOptions([
                            NSTrackingAreaOptions.ActiveInKeyWindow,
                            NSTrackingAreaOptions.InVisibleRect,
                            NSTrackingAreaOptions.MouseEnteredAndExited,
        ]);
        
        self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil));
    }

    public override func drawRect(dirtyRect: NSRect) {
        NSColor.blackColor().setFill();
        NSRectFill(dirtyRect);
    }
}

