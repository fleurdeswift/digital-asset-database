//
//  TitleInstanceVideoClipAnnotation.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import DigitalAssetDatabase
import ExtraDataStructures
import SQL
import VideoClipAnnotationEditor

public class TitleInstanceVideoClipAnnotation : VideoClipAnnotation {
    public let tagInstance: TagInstance;
    public let clipDelta: NSTimeInterval;

    public init(tagInstance: TagInstance, delta: NSTimeInterval?) {
        self.tagInstance = tagInstance;

        if let delta = delta {
            self.clipDelta = delta;
        }
        else {
            self.clipDelta = 0;
        }
    }

    public var text: String {
        get {
            return tagInstance.tag.name;
        }
    }

    public var color: VideoClipAnnotationColor {
        get {
            if let ch = tagInstance.tag.name.utf16.first {
                return VideoClipAnnotationColor.colorByIndex(Int(ch))
            }
            else {
                return VideoClipAnnotationColor.grayColor();
            }
        }
    }

    public var time: TimeRange {
        get {
            if let time = tagInstance.time {
                return time - clipDelta;
            }

            return TimeRange(start: 0, length: 0);
        }

        set {
            tagInstance.database.handle.writeAsync { (access: SQLWrite) in
                do {
                    try self.tagInstance.setTime(newValue + self.clipDelta, withAccess: access);
                }
                catch {
                }
            }
        }
    }
}
