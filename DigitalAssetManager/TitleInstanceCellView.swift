//
//  TitleInstanceCellView.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase
import ExtraDataStructures
import SQL

public let tagSeparators = NSCharacterSet(charactersInString: ",;.");

public class TitleInstanceCellView : NSTableCellView {
    @IBOutlet public weak var title:    NSTextField!;
    @IBOutlet public weak var duration: NSTextField!;
    @IBOutlet public weak var tags:     NSTokenField!;
    @IBOutlet public weak var scenes:   NSButton!;
    @IBOutlet public weak var preview:  AnimatedImagePreview!;

    public override func awakeFromNib() {
        self.tags.tokenizingCharacterSet = tagSeparators;
    }

    public var library: Library? {
        get {
            return self.window?.windowController?.document as? Library;
        }
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow();

        if let library = self.library {
            tags.delegate = library.tokenDelegate;
        }
    }

    public var titleInstance: TitleInstance! {
        didSet {
            self.title.stringValue = titleInstance.title.name;
            self.duration.stringValue = self.titleInstance.duration.secondsAsString;
            self.tags.enabled = false;
            self.scenes.title = "?";

            titleInstance.database.handle.readAsync { (access: SQLRead) -> Void in
                let results = self.titleInstance.previews(access)

                dispatch_async_main {
                    self.preview.urls = results;
                }

                let sceneCount = self.titleInstance.sceneCount(access);

                dispatch_async_main {
                    self.scenes.title = "\(sceneCount)";
                }

                do {
                    let tags = try self.titleInstance.getTagInstances(ignoreSpecialTags: true, withAccess: access);

                    dispatch_async_main {
                        self.tags.objectValue = tags;
                        self.tags.enabled = true;
                    }
                }
                catch {
                }
            }
        }
    }

    @IBAction
    public func setTitleName(sender: AnyObject?) {
        if let control = sender as? NSControl {
            titleInstance.database.handle.writeAsync { (access: SQLWrite) -> Void in
                do {
                    try self.titleInstance.title.setName(control.stringValue, withAccess: access);
                }
                catch {
                    dispatch_async_main {
                        control.stringValue = self.titleInstance.title.name;
                    }
                }
            }
        }
    }

    @IBAction
    public func setTitleTags(sender: AnyObject?) {
        if let control = sender as? NSControl {
            if let tokens = control.objectValue as? [AnyObject] {
                let database = titleInstance.database;

                database.handle.writeAsync { (access: SQLWrite) -> Void in
                    do {
                        try self.titleInstance.setTags(tokens, withAccess: access);
                    }
                    catch {
                        /// TODO
                    }
                }
            }
        }
    }
}
