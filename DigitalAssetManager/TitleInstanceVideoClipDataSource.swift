//
//  TitleInstanceVideoClipDataSource.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import DigitalAssetDatabase
import SQL
import VideoClipAnnotationEditor
import VLCKit

public class TitleInstanceVideoClipDataSource : NSObject, VideoClipDataSource {
    public var medias:        [VLCMedia];
    public let titleInstance: TitleInstance;
    public var clipsImpl =    [TitleInstanceVideoClip]();

    public init(titleInstance: TitleInstance, medias: [VLCMedia], withAccess access: SQLRead) {
        self.titleInstance = titleInstance;
        self.medias        = medias;
        super.init();

        let scenes = titleInstance.scenes(access);

        if scenes.count == 0 {
            clipsImpl.append(TitleInstanceVideoClip(dataSource: self));
        }
        else {
            clipsImpl = scenes.map { return TitleInstanceVideoClip(dataSource: self, tagInstance: $0) };
        }
    }

    public var clips: [VideoClip] {
        get {
            return clipsImpl.map { return $0 as VideoClip };
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
