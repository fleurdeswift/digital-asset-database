//
//  GeneratePreviewTask.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import ExtraDataStructures
import Foundation
import VLCKit

public class GeneratePreviewTask : NSObject, LongTask {
    public typealias ResultPair      = (image: CGImageRef?, error: NSError?);
    public typealias CompletionBlock = (images: [NSURL: ResultPair]) -> Void;

    private var captureIndex: Int = 0;
    private let captureCount: Int;
    private let columns:      Int;
    private var step:         Int = 0;

    private var size:     NSSize;
    private var media:    Dictionary<NSURL, VLCMedia>.Index;
    private var medias:   [NSURL: VLCMedia];
    private var results = [NSURL: ResultPair]();

    private var assemblyQueue: dispatch_queue_t = dispatch_queue_create("GeneratePreview.Assemble", DISPATCH_QUEUE_SERIAL);

    public var cgContext: CGContextRef?;

    private let completionBlock: CompletionBlock;
    private let targetHeight: CGFloat;

    private let fileCount:   Int;
    private let stepPerFile: Int;

    public init(medias: [NSURL: VLCMedia], completionBlock: CompletionBlock, targetHeight: Int = 200, count: Int = 16) {
        self.medias          = medias;
        self.media           = medias.startIndex;
        self.completionBlock = completionBlock;
        self.columns         = Int(sqrt(Double(count)));
        self.size            = NSSize();
        self.captureCount    = columns * columns;
        self.status          = "Initializing...";
        self.targetHeight    = CGFloat(targetHeight);
        self.fileCount       = medias.count;
        self.stepPerFile     = 2 + (captureCount * 2);
        super.init();

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            self.nextFile();
        }
    }

    public func nextFile() {
        self.captureIndex = 0;

        if media == medias.endIndex {
            finish();
            return;
        }

        let lowPriority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        let (currentURL, currentMedia) = medias[media];

        media = media.successor();

        let times = currentMedia.times(columns * columns);
        self.size = currentMedia.videoSize.sizeWithHeightPreservingAspectRatio(targetHeight);

        if self.size.height <= 0 || self.size.width == 0 {
            results[currentURL] = (nil, NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL), userInfo: nil));
            self.stepFinished(self.stepPerFile);

            dispatch_async(lowPriority) {
                self.nextFile();
            }

            return;
        }

        dispatch_async(self.assemblyQueue) {
            let tw = Int(CGFloat(self.columns) * self.size.width);
            let th = Int(CGFloat(self.columns) * self.size.height);
            let tr = tw * 4;

            self.cgContext = CGBitmapContextCreate(
                UnsafeMutablePointer<Void>(),
                tw,
                th,
                8,
                tr,
                CGColorSpaceCreateDeviceRGB(),
                CGImageAlphaInfo.NoneSkipLast.rawValue)

            self.stepFinished();
        }

        dispatch_async(lowPriority) {
            currentMedia.generatePreviewImageFor(times) { (image: CGImageRef?, error: NSError?) in
                if error != nil {
                    self.finishFile(currentURL, error: error);
                    return;
                }

                if image == nil {
                    // Last image was sent.
                    self.finishFile(currentURL, error: nil);
                    return;
                }

                let index = self.captureIndex;

                self.captureIndex++;

                dispatch_async(self.assemblyQueue) {
                    self.assembleImage(image!, atIndex: index);
                    self.stepFinished();
                }
                
                self.stepFinished();
            }

            self.status = "Capturing...";
        }
    }

    internal func assembleImage(image: CGImage, atIndex index: Int) {
        let row    = (columns - 1) - (index / columns);
        let column = index % columns;
        let rect   = CGRect(x: CGFloat(column) * size.width, y: CGFloat(row) * size.height, width: size.width, height: size.height);

        CGContextDrawImage(cgContext!, rect, image);
    }

    internal func finish() {
        dispatch_async_main {
            self.progress = 1.0;
            NSNotificationCenter.defaultCenter().postNotificationName(LongTaskProgressChanged, object: self);
            self.completionBlock(images: self.results);
        }
    }

    internal func finishFile(url: NSURL, error: NSError?) {
        dispatch_async(self.assemblyQueue) {
            if error != nil {
                self.results[url] = (CGBitmapContextCreateImage(self.cgContext), error);
            }
            else {
                self.results[url] = (CGBitmapContextCreateImage(self.cgContext), nil);
            }

            self.cgContext = nil;
            self.stepFinished();
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
                self.nextFile();
            }
        }
    }

    private func stepFinished(adv: Int = 1) {
        let totalStep = fileCount * (2 + (captureCount * 2));

        dispatch_async_main {
            self.step += adv;
            self.progress = min(0.999, Double(self.step) / Double(totalStep));
            NSNotificationCenter.defaultCenter().postNotificationName(LongTaskProgressChanged, object: self);
        }
    }

    internal(set) public var progress: Double?;

    internal(set) public var status: String {
        didSet {
            dispatch_async_main {
                NSNotificationCenter.defaultCenter().postNotificationName(LongTaskStatusChanged, object: self);
            }
        }
    }

    public func cancel() {
    }
}
