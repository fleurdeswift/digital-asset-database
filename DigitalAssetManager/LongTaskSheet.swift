//
//  LongTaskSheet.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import ExtraDataStructures

public let LongTaskProgressChanged = "LongTaskProgressChanged";
public let LongTaskStatusChanged   = "LongTaskStatusChanged";

public protocol LongTask : NSObjectProtocol {
    var progress: Double? { get }
    var status:   String  { get }

    func cancel();
}

public class LongTaskSheet: NSViewController {
    @IBOutlet public weak var progress: NSProgressIndicator?;
    @IBOutlet public weak var status: NSTextField?;
    @IBOutlet public weak var cancel: NSButton?;

    public let task: LongTask;
    private var timer: dispatch_source_t?;

    private init?(task: LongTask) {
        self.task = task;
        super.init(nibName: "LongTaskSheet", bundle: nil);

        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_MSEC)), 100 * NSEC_PER_MSEC, 10 * NSEC_PER_MSEC);
        dispatch_source_set_event_handler(timer) {
            updateProgress();
        }
        
        dispatch_resume(timer);
        self.timer = timer;

        let notificationCenter = NSNotificationCenter.defaultCenter();
        notificationCenter.addObserver(self, selector: Selector("statusChanged:"),   name: LongTaskStatusChanged,   object: task);
        notificationCenter.addObserver(self, selector: Selector("progressChanged:"), name: LongTaskProgressChanged, object: task);
    }

    public required init?(coder decoder: NSCoder) {
        self.task = decoder.decodeObjectForKey("task") as! LongTask
        super.init(coder: decoder);
    }

    public class func show(task: LongTask, parent: NSViewController) {
        let sheet = LongTaskSheet(task: task)!;
        parent.presentViewControllerAsSheet(sheet);
    }

    private func close() {
        if let t = timer {
            dispatch_source_cancel(t);
            timer = nil;
        }

        dispatch_async_main {
            if let presenting = self.presentingViewController {
                presenting.dismissViewController(self);
            }
        }
    }

    @objc
    private func progressChanged(sender: AnyObject?) {
        if updateProgress() {
            close();
        }
    }

    @objc
    private func statusChanged(sender: AnyObject?) {
        status?.stringValue = task.status;
    }

    private func updateProgress() -> Bool {
        if let progress = self.progress {
            if let p = task.progress {
                progress.indeterminate = false;
                progress.doubleValue = p * 100.0;

                if p >= 1.0 {
                    return true;
                }
            }
            else {
                progress.indeterminate = true;
            }
        }

        return false;
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if updateProgress() {
            close();
        }

        status?.stringValue = task.status;
    }

    @IBAction public func cancel(sender: AnyObject?) {
        task.cancel();
        cancel?.enabled = false;
    }
}
