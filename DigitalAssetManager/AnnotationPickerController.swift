//
//  AnnotationPicker.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase

public class AnnotationPickerController : NSViewController {
    private var library: Library!;
    private var completionBlock: (([AnyObject]) -> Void)!;

    @IBOutlet
    public weak var tokens: NSTokenField!;

    public class func create(library: Library, completionBlock: ([AnyObject]) -> Void) -> AnnotationPickerController {
        let picker = AnnotationPickerController(nibName:"AnnotationPickerController", bundle: NSBundle.mainBundle())!;

        picker.library         = library;
        picker.completionBlock = completionBlock;
        return picker;
    }

    public override func loadView() {
        super.loadView();
        tokens.delegate               = library.tokenDelegate;
        tokens.tokenizingCharacterSet = tagSeparators;
    }

    @IBAction
    public func saveTags(sender: AnyObject?) {
        if let tags = tokens.objectValue as? [AnyObject] {
            if tags.count > 0 {
                completionBlock(tags);
            }
        }

        self.view.window?.close();
    }
}
