//
//  ImportFiles.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Cocoa
import DigitalAssetDatabase
import ExtraAppKit
import ExtraDataStructures
import SQL
import VLCKit

private let ImportFilePasteboardType = "com.fds.ImportFilePasteboardType";

func CGImageWriteToFile(image: CGImageRef, _ path: String) -> Bool {
    let url = NSURL(fileURLWithPath: path);
    let mdestination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil);

    if let destination = mdestination {
        CGImageDestinationAddImage(destination, image, nil);
        return CGImageDestinationFinalize(destination);
    }

    return false;
}

private func CGImageWriteToJPEG(image: CGImageRef, _ url: NSURL) -> Bool {
    let mdestination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil);

    if let destination = mdestination {
        let options: [NSString: NSNumber] = [kCGImageDestinationLossyCompressionQuality: Double(0.7)];

        CGImageDestinationSetProperties(destination, options);
        CGImageDestinationAddImage(destination, image, nil);
        return CGImageDestinationFinalize(destination);
    }

    return false;
}

public class ImportFiles: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    public let  library: Library;
    public var  urls: [NSURL];
    public var  medias = [NSURL: VLCMedia]();
    private let queue  = dispatch_queue_create("org.fds.ImportFiles", DISPATCH_QUEUE_SERIAL);
    private var infos  = [NSURL: (codec: String, duration: NSTimeInterval)]();

    @IBOutlet public weak var playButton: NSButton?;
    @IBOutlet public weak var groupType:  NSPopUpButton!;
    @IBOutlet public weak var tableView:  NSTableView?;
    @IBOutlet public weak var tokens:     NSTokenField!;
    @IBOutlet public weak var scrubber:   NSSlider?;
    @IBOutlet public weak var video:      VLCView?;

    private var mediaPlayer: VLCMediaPlayer?;

    public init?(library: Library, urls: [NSURL]) {
        self.library = library;
        self.urls    = urls;
        super.init(nibName: "ImportFiles", bundle: nil);

        parseMedias();
    }

    public required init?(coder decoder: NSCoder) {
        self.library = decoder.decodeObjectForKey("library") as! Library;
        self.urls    = [NSURL]();
        super.init(coder: decoder);
    }

    public override func loadView() {
        super.loadView();

        if let tv = tableView {
            tv.registerForDraggedTypes([ImportFilePasteboardType]);
            tv.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal:true);
            tv.setDraggingSourceOperationMask(NSDragOperation.Every, forLocal:false);
        }

        tokens.delegate               = library.tokenDelegate;
        tokens.tokenizingCharacterSet = tagSeparators;
    }

    private func parseMedias() {
        dispatch_async(queue) {
            var openErrors         = [NSURL: ErrorType]();
            let notificationCenter = NSNotificationCenter.defaultCenter();

            for url in self.urls {
                do {
                    let media = try VLCMedia(path: url.path!, withVLC: vlc!);

                    notificationCenter.addObserver(self, selector: Selector("mediaParsed:"), name: VLCMediaParsedChanged, object: media);
                    self.medias[url] = media;

                    media.parse(true);
                }
                catch {
                    openErrors[url] = error;
                }
            }

            if openErrors.count == 0 {
                return;
            }

            dispatch_async_main {
                var errorText: String = "";

                for (url, error) in openErrors {
                    errorText += "Error parsing \(url): \(error)\n\n";
                }

                errorText = errorText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

                let alert = NSAlert();
                alert.messageText = errorText;
                alert.runModal();
            }
        }
    }

    @objc
    public func mediaPlayerTimeChanged(notification: NSNotification) {
        if let mediaPlayer = self.mediaPlayer, scrubber = self.scrubber {
            scrubber.floatValue = mediaPlayer.position * 10000;
        }
    }

    @objc
    public func mediaParsed(notification: NSNotification) {
        if let media = notification.object as? VLCMedia {
            for (url, umedia) in medias {
                if umedia === media {
                    var codec = "";

                    for track in media.tracks {
                        if !codec.isEmpty {
                            codec += ", ";
                        }

                        codec += track.description;
                    }

                    infos[url] = (codec: codec, duration: media.duration);
                    tableView?.reloadData();
                }
            }
        }
    }

    public func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return urls.count;
    }

    public func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let column = tableColumn, identifier = tableColumn?.identifier {
            if let cell = tableView.makeViewWithIdentifier(identifier, owner: self) as? NSTableCellView {
                let url = urls[row];

                if (column.identifier == "url") {
                    cell.textField?.stringValue = url.lastPathComponent!;
                }
                else if (column.identifier == "type") {
                    if let info = infos[url] {
                        cell.textField?.stringValue = info.codec;
                    }
                    else {
                        cell.textField?.stringValue = "Parsing...";
                    }
                }
                else if (column.identifier == "duration") {
                    if let info = infos[url] {
                        cell.textField?.stringValue = info.duration.secondsAsString;
                    }
                    else {
                        cell.textField?.stringValue = "Parsing...";
                    }
                }

                return cell;
            }
        }

        return nil;
    }

    public func tableView(tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return NSPasteboardItem(pasteboardPropertyList: row, ofType: ImportFilePasteboardType);
    }

    public func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation operation: NSTableViewDropOperation) -> NSDragOperation {
        if operation == NSTableViewDropOperation.On {
            return NSDragOperation.None;
        }

        return NSDragOperation.Move;
    }

    public func tableView(tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forRowIndexes rowIndexes: NSIndexSet) {
        session.draggingPasteboard.setData(NSKeyedArchiver.archivedDataWithRootObject(rowIndexes), forType:ImportFilePasteboardType);
        tableView.draggingDestinationFeedbackStyle = NSTableViewDraggingDestinationFeedbackStyle.Gap;
    }

    public func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation operation: NSTableViewDropOperation) -> Bool {
        if let data = info.draggingPasteboard().dataForType(ImportFilePasteboardType) {
            if let rows = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSIndexSet {
                let sourceRow = rows.firstIndex;

                tableView.beginUpdates();

                if sourceRow < row {
                    tableView.moveRowAtIndex(rows.firstIndex, toIndex: row - 1);
                }
                else {
                    tableView.moveRowAtIndex(rows.firstIndex, toIndex: row);
                }

                urls.moveFromIndex(rows.firstIndex, to: row);
                tableView.endUpdates();
                return true;
            }
        }

        return false;
    }

    public func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cell = tableView.makeViewWithIdentifier("url", owner: self) as? NSTableCellView {
            cell.textField?.stringValue = "<DUMMY>";
            return cell.fittingSize.height;
        }

        return 4;
    }

    public func tableViewSelectionDidChange(notification: NSNotification) {
        if let index = tableView?.selectedRow {
            if index < 0 {
                return;
            }

            let url = urls[index];

            if let media = medias[url] {
                do {
                    let mediaPlayer = try VLCMediaPlayer(media: media);

                    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("mediaPlayerTimeChanged:"), name: VLCMediaPlayerTimeChanged, object: mediaPlayer);

                    self.mediaPlayer   = mediaPlayer;
                    video?.mediaPlayer = mediaPlayer;
                    mediaPlayer.play();
                    playButton?.enabled = true;
                }
                catch let error as NSError {
                    NSAlert(error: error).runModal();
                }
                catch {
                    let alert = NSAlert();
                    alert.messageText = "\(error)";
                    alert.runModal();
                }
            }
        }
    }

    @IBAction
    public func playOrPause(sender: AnyObject?) {
        if let mediaPlayer = self.mediaPlayer {
            let state = mediaPlayer.state;

            if state == .Playing {
                mediaPlayer.pause();
            }
            else {
                mediaPlayer.play();
            }
        }
    }

    private class func produceErrorMap(images: [NSURL: (image: CGImageRef?, error: NSError?)]) -> [NSURL: NSError] {
        var errors = [NSURL: NSError]();

        for (url, pair) in images {
            if let e = pair.error {
                errors[url] = e;
            }
        }

        return errors;
    }

    private func produceFileMap(urls: [NSURL]) -> [TitleInstanceFile] {
        var results = [TitleInstanceFile]();

        for url in urls {
            if let media = medias[url] {
                let lpc = url.lastPathComponent!;

                results.append(TitleInstanceFile(
                    moveFileName:    lpc,
                    previewFileName: url.lastPathComponent(newExtension: "jpg")!,
                    duration:        media.duration))
            }
        }

        return results;
    }

    private func produceMoveMap(titleInstance: TitleInstance, urls: [NSURL]) -> [NSURL: NSURL] {
        var moves   = [NSURL: NSURL]();
        let baseURL = self.library.database.urlForTitleInstance(titleInstance.id, create: true);

        for url in urls {
            moves[url] = baseURL.URLByAppendingPathComponent(url.lastPathComponent!);
        }

        return moves;
    }

    private func produceImageMap(titleInstance: TitleInstance, urls: [NSURL]) -> [NSURL: NSURL] {
        var moves = [NSURL: NSURL]();
        let baseURL = self.library.database.urlForTitleInstance(titleInstance.id, create: true);

        for url in urls {
            moves[url] = baseURL.URLByAppendingPathComponent(url.lastPathComponent!);
        }

        return moves;
    }

    private func produceTags(database: Database, withAccess access: SQLWrite) throws -> [AnyObject] {
        var results: [AnyObject] = [try Tag.shared(StandardTagID.DropBox.rawValue, fromDatabase: database, withAccess: access)];

        if let tokens = self.tokens.objectValue {
            if let a = tokens as? [AnyObject] {
                for token in a {
                    results.append(token);
                }
            }
        }

        return results;
    }

    private func importFileAllFilesIsTitle(images: [NSURL: (image: CGImageRef?, error: NSError?)], filesAreScene: Bool, withAccess access: SQLWrite) throws -> ([TitleInstance], [NSURL: NSURL], [NSURL: CGImageRef]) {
        let database      = self.library.database;
        let title         = try Title(createWithName: self.urls[0].lastPathComponent!, inDatabase: database, withAccess: access);
        let titleInstance = try TitleInstance(createWithFiles: self.produceFileMap(urls), tags: self.produceTags(database, withAccess: access), title: title, filesAreScene: filesAreScene, inDatabase: database, withAccess: access)
        var outputImages  = [NSURL: CGImageRef]();

        for (url, pair) in images {
            if let image = pair.image {
                outputImages[self.previewURL(titleInstance, movieFile: url)] = image;
            }
        }

        return ([titleInstance], self.produceMoveMap(titleInstance, urls: self.urls), outputImages);
    }

    private func previewURL(titleInstance: TitleInstance, movieFile: NSURL) -> NSURL {
        let instanceURL = self.library.database.urlForTitleInstance(titleInstance.id, create: true);
        let previewName = movieFile.lastPathComponent(newExtension: "jpg")!;
        return instanceURL.URLByAppendingPathComponent(previewName);
    }

    private func importFileEveryFileIsTitle(images: [NSURL: (image: CGImageRef?, error: NSError?)], withAccess access: SQLWrite) throws -> ([TitleInstance], [NSURL: NSURL], [NSURL: CGImageRef]) {
        let database      = self.library.database;
        let tags          = try self.produceTags(database, withAccess: access);
        var outputImages  = [NSURL: CGImageRef]();
        var moves         = [NSURL: NSURL]();
        var titles        = [TitleInstance]();

        for url in urls {
            let urls          = [url];
            let title         = try Title(createWithName: url.lastPathComponent!, inDatabase: database, withAccess: access);
            let titleInstance = try TitleInstance(createWithFiles: self.produceFileMap(urls), tags: tags, title: title, filesAreScene: false, inDatabase: database, withAccess: access)

            for (newSource, newDestination) in produceMoveMap(titleInstance, urls: urls) {
                moves[newSource] = newDestination;
            }

            if let pair = images[url] {
                if let image = pair.image {
                    outputImages[self.previewURL(titleInstance, movieFile: url)] = image;
                }
            }

            titles.append(titleInstance);
        }

        return (titles, moves, outputImages);
    }

    @IBAction
    public func importFiles(sender: AnyObject?) {
        let presentingViewController = self.presentingViewController;
        let importType               = self.groupType.selectedTag();

        if importType == -1 {
            NSAlert(error: NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL), userInfo: nil)).runModal();
            return;
        }

        if let parentView = presentingViewController {
            parentView.dismissViewController(self);
        }

        let block = { (images: [NSURL: (image: CGImageRef?, error: NSError?)]) -> Void in
            var errors = ImportFiles.produceErrorMap(images);
            if errors.count > 0 {
                NSAlert(infoText: "Failed to generate preview images", urls: errors).runModal();
                return;
            }

            let database = self.library.database;
            do {
                try database.handle.write { (access: SQLWrite) throws in
                    var results: ([TitleInstance], [NSURL: NSURL], [NSURL: CGImageRef]);

                    switch importType {
                    case 1:
                        results = try self.importFileAllFilesIsTitle(images, filesAreScene: true, withAccess: access);
                        break;
                    case 2:
                        results = try self.importFileAllFilesIsTitle(images, filesAreScene: false, withAccess: access);
                        break;
                    default:
                        results = try self.importFileEveryFileIsTitle(images, withAccess: access);
                        break;
                    }

                    try MoveFileTask.moveFiles(results.1, presentingViewController: presentingViewController!) {
                        (errors: [NSURL: NSError]?) -> Void in
                            if let errors = errors {
                                NSAlert(infoText: "Failed to move files", urls: errors).runModal();
                            }
                    }

                    for (url, image) in results.2 {
                        CGImageWriteToJPEG(image, url);
                    }
                }
            }
            catch {
                NSAlert(infoText: "Failed to create objects in database", errorType: error).runModal();
                return;
            }
        };

        LongTaskSheet.show(GeneratePreviewTask(medias: medias, completionBlock: block), parent: presentingViewController!);
    }

    @IBAction
    public func scrub(sender: AnyObject?) {
        if let time = scrubber?.floatValue {
            mediaPlayer?.position = time / 10000.0;
        }
    }

    @IBAction
    public func cancel(sender: AnyObject?) {
        if let parentView = self.presentingViewController {
            parentView.dismissViewController(self);
        }
    }

    public override func keyDown(theEvent: NSEvent) {
        if let char = theEvent.characters?.utf16.first {
            switch (Int(char)) {
            case NSDeleteFunctionKey:
                deleteForward(self);
                return;
            case NSDeleteCharacter:
                deleteForward(self);
                return;
            case NSBackspaceCharacter:
                deleteForward(self);
                return;
            default:
                break;
            }
        }

        super.keyDown(theEvent);
    }

    @IBAction
    public override func deleteForward(sender: AnyObject?) {
        if let tv = tableView {
            let row = tv.selectedRow;

            if row < 0 {
                NSBeep();
                return;
            }

            tv.beginUpdates();
            tv.removeRowsAtIndexes(NSIndexSet(index: row), withAnimation: NSTableViewAnimationOptions.EffectGap);
            urls.removeAtIndex(row);
            tv.endUpdates();
        }
    }

    @IBAction
    public override func deleteBackward(sender: AnyObject?) {
        deleteForward(self);
    }
}
