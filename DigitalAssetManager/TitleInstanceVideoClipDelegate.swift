//
//  TitleInstanceVideoClipDelegate.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import DigitalAssetDatabase;
import VLCKit
import VideoClipAnnotationEditor

public class TitleInstanceVideoClipDelegate : NSObject, VideoClipDelegate {
    private var mediaPlayer: VLCMediaPlayer;
    private var lastPoint:   VideoClipPoint?;

    public init(mediaPlayer: VLCMediaPlayer) {
        self.mediaPlayer = mediaPlayer;
    }

    public func currentTimeChanged(videoClipView: VideoClipView, point: VideoClipPoint?, event: NSEvent?) {
        if let time = point?.time {
            self.lastPoint = point;

            if mediaPlayer.playing {
                if let event = event {
                    if event.type != NSEventType.LeftMouseDown || event.clickCount == 1 {
                        return;
                    }
                }
            }

            self.mediaPlayer.time = time;
        }
    }

    public func selectionChanged(videoClipView: VideoClipView, range: VideoClipRange?) {
    }

    public func selectionChanged(videoClipView: VideoClipView, annotations: Set<HashAnnotation>?) {
    }
}
