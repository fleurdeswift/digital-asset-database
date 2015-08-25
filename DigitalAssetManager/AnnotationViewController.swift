//
//  AnnotationViewController.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase;
import ExtraDataStructures;
import SQL
import VLCKit
import VideoClipAnnotationEditor

public class AnnotationVideoBaseView : NSView {
    public override var acceptsFirstResponder: Bool {
        get {
            return true;
        }
    }

    public override var canBecomeKeyView: Bool {
        get {
            return true;
        }
    }
}

public class AnnotationVideoBackgroundView : NSView {
    public override var opaque: Bool {
        get {
            return true;
        }
    }

    public override func drawRect(dirtyRect: NSRect) {
        NSColor(genericGamma22White: 0.2, alpha: 1.0).setFill();
        NSRectFill(dirtyRect);
    }
}

public class AnnotationViewController: NSViewController {
    @IBOutlet public weak var vlcView:     VLCView!;
    @IBOutlet public weak var annotations: VideoClipView!;
    @IBOutlet public weak var tokens:      NSTokenField!;

    public var titleInstance: TitleInstance! {
        didSet {
            let titleInstance = self.titleInstance;

            titleInstance.database.handle.readAsync { (access: SQLRead) in
                do {
                    let files  = try titleInstance.filesURL(access);
                    var medias = [VLCMedia]();

                    for file in files {
                        medias.append(try VLCMedia(path: file.path!, withVLC: vlc!));
                    }

                    let mediaPlayer = try VLCMediaPlayer(medias: medias);
                    let dataSource  = TitleInstanceVideoClipDataSource(titleInstance: titleInstance, medias: medias, withAccess: access);
                    let tags        = try titleInstance.getTagInstances(ignoreSpecialTags: true, withAccess: access)

                    dispatch_async_main {
                        self.vlcView.mediaPlayer    = mediaPlayer;
                        self.annotations.dataSource = dataSource;
                        self.annotations.delegate   = TitleInstanceVideoClipDelegate(mediaPlayer: mediaPlayer);
                        self.tokens.objectValue     = tags;
                        mediaPlayer.play();
                    }

                }
                catch {
                }
            }
        }
    }

    private var library: Library? {
        get {
            return self.view.window?.windowController?.document as? Library;
        }
    }

    public func showAnnotationPicker(str: String, event: NSEvent) {
        let selection     = self.annotations.selection;
        //let currentTime   = self.annotations.currentTime;
        let titleInstance = self.titleInstance;

        if selection == nil {
            return;
        }

        let popupController = AnnotationPickerController.create(self.library!) {
            (tokens: [AnyObject]) -> Void in

            if let selection = selection {
                if let clip = selection.clip as? TitleInstanceVideoClip {
                    titleInstance.database.handle.writeAsync { (access: SQLWrite) in
                        do {
                            try titleInstance.setTags(tokens, atTime:clip.toBackingTime(selection.time), withAccess:access);
                        }
                        catch {
                        }
                    }
                }
            }
        }

        let popup = NSPopover();
        popup.behavior              = NSPopoverBehavior.Semitransient;
        popup.appearance            = NSAppearance(named: NSAppearanceNameVibrantDark);
        popup.contentViewController = popupController;
        popup.showRelativeToRect(self.vlcView.bounds, ofView: self.vlcView, preferredEdge: NSRectEdge.MinY);
        popupController.view.window?.sendEvent(event);
    }

    public override func viewDidAppear() {
        if let library = self.library {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("timedTagsChanged:"), name: DADTitleInstanceTagsChangedNotification, object: library);
            tokens.delegate = library.tokenDelegate;
            tokens.tokenizingCharacterSet = tagSeparators;
        }
    }

    @IBAction
    public func saveTitleTags(sender: AnyObject?) {
        let titleInstance = self.titleInstance;

        if let tags = tokens.objectValue as? [AnyObject] {
            titleInstance.database.handle.writeAsync { access in
                do {
                    try titleInstance.setTags(tags, withAccess: access);
                }
                catch {
                }
            }
        }
    }

    @objc
    private func timedTagsChanged(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let titleInstance = userInfo["TitleInstance"] as? TitleInstance {
                if titleInstance !== self.titleInstance {
                    return;
                }

                self.annotations.reloadData();
            }
        }
    }

    public override func keyDown(ev: NSEvent) {
        if let characters = ev.charactersIgnoringModifiers {
            if characters == " " {
                let mediaPlayer = vlcView.mediaPlayer;

                switch (vlcView.mediaPlayer.state) {
                case .Unknown, .Opening, .Buffering, .Paused:
                    mediaPlayer.play();
                    break;
                case .Stopped, .Ended, .Error:
                    mediaPlayer.time = 0;
                    mediaPlayer.play();
                    break;
                case .Playing:
                    mediaPlayer.pause();
                }

                return;
            }
        }

        let modifiers = ev.modifierFlags.intersect(NSEventModifierFlags.DeviceIndependentModifierFlagsMask);

        if modifiers.isEmpty || modifiers == NSEventModifierFlags.ShiftKeyMask {
            if let characters = ev.characters {
                if let firstChar = characters.utf16.first {
                    if (NSCharacterSet.alphanumericCharacterSet().characterIsMember(firstChar)) {
                        showAnnotationPicker(characters, event: ev);
                        return;
                    }
                }
            }
        }

        super.keyDown(ev);
    }

    public override func dismissController(sender: AnyObject?) {
        if let mediaPlayer = vlcView?.mediaPlayer {
            mediaPlayer.stop();
        }
    }

    public class func create() -> AnnotationViewController {
        return AnnotationViewController(nibName:"AnnotationViewController", bundle: NSBundle.mainBundle())!;
    }

    public override var representedObject: AnyObject? {
        didSet {
            if let info = self.representedObject as? [String: AnyObject] {
                self.titleInstance = info["object"] as! TitleInstance;
            }
        }
    }

    @IBAction
    public func moveToNextItemInDropbox(sender: AnyObject?) {
        do {
            if let editor = tokens.currentEditor() {
                tokens.endEditing(editor);
            }

            try titleInstance.database.handle.read { (access: SQLRead) throws in
                if let before = self.titleInstance.nextItemInDropbox(access) {
                    dispatch_async_main {
                        self.titleInstance = before;
                    }
                }
            }
        }
        catch {
        }
    }

    @IBAction
    public func moveToPreviousItemInDropbox(sender: AnyObject?) {
        do {
            if let editor = tokens.currentEditor() {
                tokens.endEditing(editor);
            }

            try titleInstance.database.handle.read { (access: SQLRead) throws in
                if let after = self.titleInstance.previousItemInDropbox(access) {
                    dispatch_async_main {
                        self.titleInstance = after;
                    }
                }
            }
        }
        catch {
        }
    }

    @IBAction
    public func moveOutsideDropbox(sender: AnyObject?) {
        do {
            try titleInstance.database.handle.write { (access: SQLWrite) throws in
                try self.titleInstance.removeFromDropbox(access);
            }
        }
        catch {
        }
    }
}
