//
//  MoveFileTask.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import Cocoa

public class MoveFileTask : NSObject, LongTask {
    public var progress: Double?;
    public var status:   String = "Moving files..."

    public func cancel() {
    }

    public let links: [String: String];
    public let moves: [NSURL: NSURL];
    public let block: ([NSURL: NSError]?) -> Void

    public init(linkMoves: [String: String], manualMoves: [NSURL: NSURL], manualAttributes: [NSURL: [String: AnyObject]], completionBlock: ([NSURL: NSError]?) -> Void) {
        self.links = linkMoves;
        self.moves = manualMoves;
        self.block = completionBlock;
        super.init();

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            var totalBytes: UInt64 = 0;
            var readed:     UInt64 = 0;

            for (_, attributes) in manualAttributes {
                if let bytes = attributes[NSFileSize] as? NSNumber {
                    totalBytes += bytes.unsignedLongLongValue;
                }
            }

            var blockIndex = 0;
            let blockSize = 65536;
            let block     = Darwin.malloc(blockSize);
            defer { Darwin.free(block); }

            for (sourceURL, destinationURL) in manualMoves {
                let input  = NSInputStream(URL: sourceURL)!;
                let output = NSOutputStream(URL: destinationURL, append: false)!;

                input.open();
                output.open();

                defer {
                    input.close();
                    output.close();
                }

                while true {
                    let blockReaded = input.read(UnsafeMutablePointer<UInt8>(block), maxLength: blockSize);

                    if blockReaded == 0 {
                        break;
                    }
                    else if blockReaded < 0 {
                        self.revert(sourceURL, error: input.streamError);
                        return;
                    }

                    readed += UInt64(blockReaded);

                    if output.write(UnsafeMutablePointer<UInt8>(block), maxLength: blockReaded) < 0 {
                        self.revert(destinationURL, error: output.streamError);
                        return;
                    }

                    if blockIndex++ > 16 {
                        blockIndex = 0;

                        let up = readed;
                        let upt = totalBytes;

                        dispatch_async(dispatch_get_main_queue()) {
                            self.progress = min(0.999, Double(up) / Double(upt));
                            NSNotificationCenter.defaultCenter().postNotificationName(LongTaskProgressChanged, object: self);
                        }
                    }
                }
            }

            self.commit();
        }
    }

    public class func moveFiles(files: [NSURL: NSURL], presentingViewController: NSViewController, completionBlock: ([NSURL: NSError]?) -> Void) throws {
        if let task = try self.moveFiles(files, completionBlock: completionBlock) {
            LongTaskSheet.show(task, parent: presentingViewController);
        }
    }

    /// This function returns nil if the move operation can be performed using the POSIX command
    /// rename.
    public class func moveFiles(files: [NSURL: NSURL], completionBlock: ([NSURL: NSError]?) -> Void) throws -> LongTask? {
        let manager     = NSFileManager.defaultManager();
        var manualMoves = [NSURL: NSURL]();
        var linkMoves   = [String: String]();
        var attributes  = [NSURL: [String: AnyObject]]();

        for (source, destination) in files {

            if  source.fileURL && destination.fileURL {
                if let sourcePath = source.path, destinationPath = destination.path {
                    let attr = try manager.attributesOfItemAtPath(sourcePath);

                    if Darwin.link(sourcePath, destinationPath) == 0 {
                        linkMoves[sourcePath] = destinationPath;
                        continue;
                    }
                    
                    attributes[source] = attr;
                }
            }

            manualMoves[source] = destination;
        }

        if manualMoves.count == 0 {
            for (sourcePath, _) in linkMoves {
                Darwin.unlink(sourcePath);
            }

            completionBlock(nil);
            return nil;
        }

        return MoveFileTask(linkMoves: linkMoves, manualMoves: manualMoves, manualAttributes: attributes, completionBlock: completionBlock);
    }

    private func commit() {
        for (sourcePath, _) in links {
            Darwin.unlink(sourcePath);
        }

        for (sourceURL, _) in moves {
            if sourceURL.fileURL {
                if let path = sourceURL.path {
                    Darwin.unlink(path);
                }
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.progress = 1.0;
            NSNotificationCenter.defaultCenter().postNotificationName(LongTaskProgressChanged, object: self);
            self.block(nil);
        }
    }

    private func revert(url: NSURL, error: NSError?) {
        for (_, destinationPath) in links {
            Darwin.unlink(destinationPath);
        }

        for (_, destinationURL) in moves {
            if destinationURL.fileURL {
                if let path = destinationURL.path {
                    Darwin.unlink(path);
                }
                else {
                    assert(false);
                }
            }

            assert(false);
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.progress = 1.0;
            NSNotificationCenter.defaultCenter().postNotificationName(LongTaskProgressChanged, object: self);

            if let e = error {
                self.block([url: e]);
            }
            else {
                self.block([url: NSError(domain: NSPOSIXErrorDomain, code: Int(EFAULT), userInfo: nil)]);
            }
        }
    }
}
