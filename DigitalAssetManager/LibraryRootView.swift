//
//  LibraryRootView.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa

public class LibraryRootView : NSView {
    public override func awakeFromNib() {
        self.registerForDraggedTypes([NSURLPboardType, NSFilenamesPboardType]);
    }

    public override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return [NSDragOperation.Copy, NSDragOperation.Move];
    }

    public override func draggingUpdated(sender: NSDraggingInfo) -> NSDragOperation {
        return [NSDragOperation.Copy, NSDragOperation.Move];
    }

    public override func prepareForDragOperation(sender: NSDraggingInfo) -> Bool {
        return true;
    }

    public override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard();

        if let types = pasteboard.types {
            if types.contains(NSFilenamesPboardType) {
                let rawData = sender.draggingPasteboard().propertyListForType(NSFilenamesPboardType);

                if let files = rawData as? [String] {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_MSEC)), dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName(DAMFileDropped, object: self, userInfo: [
                            "urls": files.map { return NSURL(fileURLWithPath: $0) }
                        ]);
                    }

                    return true;
                }
            }
            else if types.contains(NSURLPboardType) {
                let rawData = sender.draggingPasteboard().propertyListForType(NSURLPboardType);

                if let rawURLs = rawData as? [String] {
                    var urls = [NSURL]();

                    for rawURL in rawURLs {
                        if rawURL.isEmpty {
                            continue;
                        }

                        urls.append(NSURL(fileURLWithPath: rawURL));
                    }

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_MSEC)), dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotificationName(DAMFileDropped, object: self, userInfo: [
                            "urls": urls
                        ]);
                    }

                    return true;
                }
            }
        }

        return false;
    }
}
