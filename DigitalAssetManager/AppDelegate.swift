//
//  AppDelegate.swift
//  DigitalAssetManager
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import VLCKit

public var vlc: VLC?;

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(notification: NSNotification) {
        do {
            vlc = try VLC(arguments: []);
        }
        catch let error as NSError {
            NSAlert(error: error).runModal();
        }
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }

    func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
        return false;
    }
}
