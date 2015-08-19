//
//  TagCellView.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase

public class TagCellView : NSTableCellView, NSTextFieldDelegate {
    public var representedTag: Tag? {
        didSet {
            textField!.stringValue = representedTag!.name;
        }
    }

    @objc
    public func control(control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        return true;
    }
    
    @objc
    public func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let value = control.stringValue;
    
        if value.characters.count > 0 {
            // TODO
            assert(false);
            return true;
        }
        
        return false;
    }
}
