//
//  AnimatedImagePreview.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import ExtraDataStructures

public class AnimatedImagePreview : NSView {
    public var urls = [NSURL]() {
        didSet {
            let urlsRetain = self.urls;

            images.removeAll();
            dispatch_async_global {
                for url in urlsRetain {
                    let provider = CGDataProviderCreateWithURL(url);

                    if let image = CGImageCreateWithJPEGDataProvider(provider, UnsafePointer<CGFloat>(), false, CGColorRenderingIntent.RenderingIntentDefault) {
                        dispatch_async_main {
                            self.images.append(image);
                            self.needsDisplay = true;
                        }
                    }
                }
            }
        }
    }

    public var index: Int = 0;
    public var images = [CGImage]();

    public override func updateTrackingAreas() {
        let options = NSTrackingAreaOptions([
                            NSTrackingAreaOptions.ActiveInKeyWindow,
                            NSTrackingAreaOptions.InVisibleRect,
                            NSTrackingAreaOptions.MouseEnteredAndExited,
        ]);
        
        self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil));
    }

    private var timer: NSTimer?;

    public override func viewDidHide() {
        super.viewDidHide();
        
        if let timer = timer {
            timer.invalidate();
            self.timer = nil;
        }
    }

    public override func mouseEntered(theEvent: NSEvent) {
        if timer == nil {
            timer = NSTimer(timeInterval: 0.50, target: self, selector: Selector("nextImage:"), userInfo: nil, repeats: true);
            NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes);
        }
    }

    public override func mouseExited(theEvent: NSEvent) {
        if let timer = timer {
            timer.invalidate();
            self.timer = nil;
        }
    }

    @objc
    public func nextImage(sender: AnyObject?) {
        index++;
        needsDisplay = true;
    }

    public override func drawRect(dirtyRect: NSRect) {
        if images.count == 0 {
            NSColor.blackColor().setFill();
            NSRectFill(dirtyRect);
            return;
        }

        if let context = NSGraphicsContext.currentContext()?.CGContext {
            let max = images.count * 16;

            if index >= max {
                index = 0;
            }

            let fileIndex = index / 16;
            let file      = images[fileIndex];
            let cellIndex = index % 16;

            let w      = CGImageGetWidth(file);
            let h      = CGImageGetHeight(file);
            let row    = cellIndex / 4;
            let column = cellIndex % 4;

            let part = CGImageCreateWithImageInRect(file, CGRect(x: column * (w / 4), y: row * (h / 4), width: w / 4, height: h / 4));

            CGContextDrawImage(context, self.bounds, part);
        }
    }
}

