//
//  NSAlert+URL.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import AppKit

public extension NSAlert {
    public convenience init(infoText: String, errorType: ErrorType) {
        self.init();

        self.informativeText = infoText;
        self.messageText     = "\(errorType)";
    }

    public convenience init(infoText: String, urls: [NSURL: NSError]) {
        self.init();

        let lines: [String] = urls.map({ return "\($0): \($1)"});

        self.informativeText = infoText;
        self.messageText     = "\n".join(lines);
    }
}
