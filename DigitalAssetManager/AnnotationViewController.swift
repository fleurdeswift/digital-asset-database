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

                    dispatch_async_main {
                        self.vlcView.mediaPlayer    = mediaPlayer;
                        self.annotations.dataSource = dataSource;
                        self.annotations.delegate   = TitleInstanceVideoClipDelegate(mediaPlayer: mediaPlayer);
                        mediaPlayer.play();
                    }
                }
                catch {
                }
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
}
