//
//  NSSize+AspectRatio.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation

public extension NSSize {
    public func sizeWithHeightPreservingAspectRatio(height: CGFloat) -> NSSize {
        if self.height == 0 {
            return NSSize(width: 0, height: 0);
        }

        if self.height < height {
            return self;
        }

        return NSSize(width: floor(self.width / self.height * height), height: height);
    }
}
