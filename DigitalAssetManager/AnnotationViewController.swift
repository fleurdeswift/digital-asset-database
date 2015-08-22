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

public class TitleInstanceVideoClipDataSource : NSObject, VideoClipDataSource {
    public let titleInstance: TitleInstance;

    public init(titleInstance: TitleInstance, withAccess access: SQLRead) {
        self.titleInstance = titleInstance;

        let scenes = titleInstance.scenes(access);

        if scenes.count == 0 {
        }
        else {
        }
    }

    public var clips: [VideoClip] {
        get {
            return [];
        }
    }

    public var previewHeight: Int {
        get {
            return 100;
        }
    };

    public var sampleRate: NSTimeInterval {
        get {
            return clamp(titleInstance.duration, 0.5, 5);
        }
    };
}

public class AnnotationViewController: NSSplitViewController {
    @IBOutlet public weak var vlcView: VLCView!;
    @IBOutlet public weak var annotations: VideoClipView!;

    public var titleInstance: TitleInstance! {
        didSet {
            let titleInstance = self.titleInstance;

            titleInstance.database.handle.readAsync { (access: SQLRead) in
                let dataSource = TitleInstanceVideoClipDataSource(titleInstance: titleInstance, withAccess: access);

                dispatch_async_main {
                    self.annotations.dataSource = dataSource;
                }
            }

            titleInstance.database.handle.readAsync { (access: SQLRead) in
                do {
                    let files  = try titleInstance.filesURL(access);
                    var medias = [VLCMedia]();

                    for file in files {
                        medias.append(try VLCMedia(path: file.path!, withVLC: vlc!));
                    }

                    let mediaPlayer = try VLCMediaPlayer(medias: medias);

                    dispatch_async_main {
                        self.vlcView.mediaPlayer = mediaPlayer;
                    }
                }
                catch {
                }
            }
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
