//
//  TitleInstanceVideoClip.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import DigitalAssetDatabase
import VideoClipAnnotationEditor
import VLCKit

public class TitleInstanceVideoClip : VideoClip {
    public weak var dataSource:  TitleInstanceVideoClipDataSource!;
    public var      tagInstance: TagInstance?;

    public init(dataSource: TitleInstanceVideoClipDataSource) {
        self.dataSource = dataSource;
    }

    public init(dataSource: TitleInstanceVideoClipDataSource, tagInstance: TagInstance) {
        self.dataSource  = dataSource;
        self.tagInstance = tagInstance;
    }

    public var duration: NSTimeInterval {
        get {
            if let time = tagInstance?.time {
                return time.length;
            }

            if let titleInstance = dataSource?.titleInstance {
                return titleInstance.duration;
            }

            return 0;
        }
    }

    public var annotations: [VideoClipAnnotation] {
        get {
            return [];
        }
    }

    public var previewWidth: Int {
        get {
            if let dataSource = dataSource {
                return Int(dataSource.medias[0].videoSize.sizeWithHeightPreservingAspectRatio(100).width);
            }

            return 120;
        }
    }

    internal var previewSize: NSSize {
        get {
            if let dataSource = dataSource {
                return dataSource.medias[0].videoSize.sizeWithHeightPreservingAspectRatio(100);
            }

            return NSSize(width: 120, height: 100);
        }
    }

    private func adjustTime(time: NSTimeInterval) -> NSTimeInterval {
        if time < 0 {
            return -1;
        }

        if let tagTime = self.tagInstance?.time {
            return max(time, tagTime.end) + tagTime.start;
        }

        return time;
    }

    public func imageAtTime(time: NSTimeInterval, completionBlock: (image: CGImageRef?, error: NSError?) -> NSTimeInterval) {
        if let dataSource = dataSource {
            VLCMedia.generatePreviewImageAt(adjustTime(time), size: self.previewSize, inMedias: dataSource.medias) { (image: CGImageRef?, error: NSError?) -> NSTimeInterval in
                return self.adjustTime(completionBlock(image: image, error: error))
            }
        }
        else {
            completionBlock(image: nil, error: NSError(domain: NSPOSIXErrorDomain, code: Int(EINTR), userInfo: nil));
        }
    }
}
