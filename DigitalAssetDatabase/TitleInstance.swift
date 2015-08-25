//
//  TitleInstance.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import ExtraDataStructures
import SQL

public struct TitleInstanceFile {
    public var moveFileName:    String;
    public var previewFileName: String;
    public var duration:        NSTimeInterval;

    public init(moveFileName: String, previewFileName: String, duration: NSTimeInterval) {
        self.moveFileName    = moveFileName;
        self.previewFileName = previewFileName;
        self.duration        = duration;
    }
}

private let titleInstanceCache = ReferenceCache<String, TitleInstance>();

public class TitleInstance {
    public let database: Database;
    public let id:       String;

    private var _title: Title!;
    public var title: Title {
        get {
            return _title;
        }
    }

    private func setTitle(newValue: Title, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_title_instance SET dad_title_id = ? WHERE dad_title_instance_id = ?")
        try statement.bind(title.id, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        self._title = newValue;
    }

    private var _duration: NSTimeInterval = 0;
    public var duration: NSTimeInterval {
        get {
            return _duration;
        }
    }

    private func setDuration(newValue: NSTimeInterval, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_title_instance SET duration = ? WHERE dad_title_instance_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        self._duration = newValue;
    }

    private var _dateProduced: NSTimeInterval?;
    public var dateProduced: NSTimeInterval? {
        get {
            return _dateProduced;
        }
    }

    public func setDateProduced(newValue: NSTimeInterval?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_title_instance SET date_produced = ? WHERE dad_title_instance_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        self._dateProduced = newValue;
    }

    private var _datePublished: NSTimeInterval?;
    public var datePublished: NSTimeInterval? {
        get {
            return _datePublished;
        }
    }

    private func setDatePublished(newValue: NSTimeInterval?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_title_instance SET date_published = ? WHERE dad_title_instance_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        self._datePublished = newValue;
    }

    public let dateAdded: NSTimeInterval;
    
    private var _dateModified: NSTimeInterval = 0;
    public var dateModified: NSTimeInterval {
        get {
            return _dateModified;
        }
    }

    private func setDateModified(newValue: NSTimeInterval, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_title_instance SET date_modified = ? WHERE dad_title_instance_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _dateModified = newValue;
    }

    public init(createWithFiles files: [TitleInstanceFile], tags: [AnyObject]?, title: Title?, filesAreScene: Bool, inDatabase database: Database, withAccess access: SQLWrite) throws {
        var duration: Double = 0;
    
        for file in files {
            duration += file.duration;
        }
        
        let now = NSDate().timeIntervalSince1970;

        self.database      = database;
        self.id            = Database.createNewID();
        self._duration     = duration;
        self._title        = title;
        self._dateModified = now;
        self.dateAdded     = now;

        let realTitle: Title;

        if let t = title {
            realTitle = t;
        }
        else {
            realTitle = try Title(createWithName: "", inDatabase: database, withAccess: access);
        }

        var statement = try access.prepare("INSERT INTO dad_title_instance (dad_title_instance_id, dad_title_id, duration, date_added, date_modified) VALUES (?,?,?,?,?)")
        
        try statement.bind(self.id,      atIndex: 1);
        try statement.bind(realTitle.id, atIndex: 2);
        try statement.bind(duration,     atIndex: 3);
        try statement.bind(now,          atIndex: 4);
        try statement.bind(now,          atIndex: 5);
        try statement.step();

        statement = try access.prepare("INSERT INTO dad_tag_instance (dad_tag_instance_id, dad_tag_id, dad_title_id, dad_title_instance_id, start, end, data) VALUES (?,?,?,?,?,?,?)")
        
        try statement.bind(realTitle.id,                atIndex: 3);
        try statement.bind(self.id,                     atIndex: 4);

        var current: Double = 0;

        let fileTag    = StandardTagID.File.rawValue;
        let previewTag = StandardTagID.Preview.rawValue;
        let sceneTag   = StandardTagID.Scene.rawValue;

        for file in files {
            var tagInstanceID = Database.createNewID();
            try statement.bind(tagInstanceID,     atIndex: 1);
            try statement.bind(fileTag,           atIndex: 2);
            try statement.bind(current,           atIndex: 5);
            current += file.duration;
            try statement.bind(current,           atIndex: 6);
            try statement.bind(file.moveFileName, atIndex: 7);
            try statement.step();
            try statement.reset();

            tagInstanceID = Database.createNewID();
            
            try statement.bind(tagInstanceID,        atIndex: 1);
            try statement.bind(previewTag,           atIndex: 2);
            try statement.bind(file.previewFileName, atIndex: 7);
            try statement.step();
            try statement.reset();

            if filesAreScene {
                tagInstanceID = Database.createNewID();
            
                try statement.bind(tagInstanceID, atIndex: 1);
                try statement.bind(sceneTag,      atIndex: 2);
                try statement.bindNull(7);
                try statement.step();
                try statement.reset();
            }
        }

        if let tags = tags {
            let tagsNormalized = database.normalizeTagTokens(tags, withAccess: access);
            try statement.bindNull(5); // start
            try statement.bindNull(6); // end
            try statement.bindNull(7); // data

            for tagAny in tagsNormalized {
                if let tag = tagAny as? Tag {
                    let tagInstanceID = Database.createNewID();
                
                    try statement.bind(tagInstanceID, atIndex: 1);
                    try statement.bind(tag.id,        atIndex: 2);
                    try statement.step();
                    try statement.reset();
                }
            }
        }

        titleInstanceCache.getOrSet(self.id, value: self)
        database.fireTitleInstanceTagsChanged(self, tags: [])
    }

    internal init(id: String, title: Title, duration: NSTimeInterval, dateProduced: NSTimeInterval?, datePublished: NSTimeInterval?, dateAdded: NSTimeInterval, dateModified: NSTimeInterval, fromDatabase database: Database) {
        self.database       = database;
        self.id             = id;
        self._title         = title;
        self._duration      = duration;
        self._dateProduced  = dateProduced;
        self._datePublished = datePublished;
        self._dateModified  = dateModified;
        self.dateAdded      = dateAdded;
    }
    
    public class func optionalShared(id: String?, fromDatabase database: Database, withAccess access: SQLRead) -> TitleInstance? {
        if let nnid = id {
            do {
                try shared(nnid, fromDatabase: database, withAccess: access);
            }
            catch {
            }
        }
        
        return nil;
    }
    
    public class func shared(statement: SQLStatement, fromDatabase database: Database, withAccess access: SQLRead) throws -> TitleInstance {
        let id    = statement.columnString(0)!;
        let title = try Title.shared(statement.columnString(1)!, fromDatabase: database, withAccess: access);
        
        return titleInstanceCache.get(id) {
            return TitleInstance(
                id:            id,
                title:         title,
                duration:      statement.columnDouble(2),
                dateProduced:  statement.columnDouble(3),
                datePublished: statement.columnDouble(4),
                dateAdded:     statement.columnDouble(5),
                dateModified:  statement.columnDouble(6),
                fromDatabase:  database);
        }
    }
    
    public class func shared(id: String, fromDatabase database: Database, withAccess access: SQLRead) throws -> TitleInstance {
        return try titleInstanceCache.get(id) {
            let statement = try access.prepare("SELECT * FROM dad_title_instance WHERE dad_title_instance_id = ?")
            try statement.bind(id, atIndex: 1);
            try statement.step()
            return try shared(statement, fromDatabase: database, withAccess: access);
        }
    }

    public var url: NSURL {
        get {
            return database.urlForTitleInstance(self.id);
        }
    }

    public func sceneCount(access: SQLRead) -> Int {
        do {
            let statement = try access.prepare("SELECT COUNT(*) FROM dad_tag_instance WHERE dad_title_instance_id = '\(self.id)' AND dad_tag_id = '\(StandardTagID.Scene.rawValue)'")

            if try statement.step() {
                return statement.columnInt(0)
            }
        }
        catch {
        }

        return 0;
    }

    public func scenes(access: SQLRead) -> [TagInstance] {
        do {
            let statement = try access.prepare("SELECT * FROM dad_tag_instance WHERE dad_title_instance_id = '\(self.id)' AND dad_tag_id = '\(StandardTagID.Scene.rawValue)'")
            var results   = [TagInstance]();

            while try statement.step() {
                try results.append(TagInstance.shared(statement, fromDatabase: database, withAccess: access))
            }

            return results;
        }
        catch {
        }

        return [];
    }

    public func previews(access: SQLRead) -> [NSURL] {
        do {
            let statement = try access.prepare("SELECT data FROM dad_tag_instance WHERE dad_title_instance_id = '\(self.id)' AND dad_tag_id = '\(StandardTagID.Preview.rawValue)' ORDER BY start")
            var results = [NSURL]();
            let u = self.url;

            while try statement.step() {
                results.append(u.URLByAppendingPathComponent(statement.columnString(0)!));
            }

            return results;
        }
        catch {
            return [];
        }
    }

    public func getTagInstances(ignoreSpecialTags ignoreSpecialTags: Bool, withAccess access: SQLRead) throws -> [TagInstance] {
        let sql       = "SELECT * FROM dad_tag_instance WHERE dad_title_instance_id = '\(self.id)' AND start IS NULL AND end IS NULL";
        let statement = try access.prepare(sql);
        var results   = [TagInstance]();

        while try statement.step() {
            results.append(try TagInstance.shared(statement, fromDatabase: database, withAccess: access));
        }

        if ignoreSpecialTags {
            results = results.filter { return !$0.tag.isSpecial }
        }
        
        return results;
    }

    public func getTimedTagInstances(time: TimeRange?, withAccess access: SQLRead) throws -> [TagInstance] {
        let sql       = "SELECT * FROM dad_tag_instance WHERE dad_title_instance_id = '\(self.id)' AND start IS NOT NULL AND end IS NOT NULL AND dad_tag_id NOT IN (\(StandardTagIDs))";
        let statement = try access.prepare(sql);
        var results   = [TagInstance]();

        while try statement.step() {
            results.append(try TagInstance.shared(statement, fromDatabase: database, withAccess: access));
        }

        return results;
    }

    public func setTags(tokens: [AnyObject], atTime time: TimeRange, withAccess access: SQLWrite) throws -> [TagInstance] {
        let tags    = database.normalizeTagTokens(tokens, withAccess: access);
        var results = [TagInstance]();

        for entry in tags {
            if let tag = entry as? Tag {
                results.append(try TagInstance(createWithTag: tag, atTime: time, titleInstance: self, inDatabase: database, withAccess: access));
            }
            else if let tagInstance = entry as? TagInstance {
                try tagInstance.setTime(time, withAccess: access);
                results.append(tagInstance);
            }
        }

        database.fireTitleInstanceTagsChanged(self, tags: results)
        return results;
    }

    public func setTags(tokens: [AnyObject], withAccess access: SQLWrite) throws -> [TagInstance] {
        let currentInstances = Set<TagOrInstance>(try getTagInstances(ignoreSpecialTags: true, withAccess: access).map({ return TagOrInstance.Instance(instance: $0) }));
        if currentInstances.count == 0 && tokens.count == 0 {
            // Nothing to do.
            return [];
        }

        let expectedInstances = Set<TagOrInstance>(database.normalizeTagTokens(tokens, withAccess: access).map({ return TagOrInstance.create($0) }))
        let toCreate = expectedInstances.subtract(currentInstances);
        let toDelete = currentInstances.subtract(expectedInstances);
        if toCreate.count == 0 && toDelete.count == 0 {
            // Nothing to do.
            return currentInstances.map { return $0.toInstance() };
        }

        var toKeep: [TagInstance] = currentInstances.intersect(expectedInstances).map { return $0.toInstance() };

        for create in toCreate {
            switch (create) {
            case .Template(let tag):
                toKeep.append(try TagInstance(createWithTag: tag, titleInstance: self, inDatabase: database, withAccess: access));
                break;
            case .Instance(let instance):
                toKeep.append(instance);
                break;
            }
        }

        for delete in toDelete {
            switch (delete) {
            case .Instance(let instance):
                try instance.delete(access);
                break;
            default:
                break;
            }
        }

        database.fireTitleInstanceTagsChanged(self, tags: toKeep)
        return toKeep;
    }

    public func nextItemInDropbox(access: SQLRead) -> TitleInstance? {
        var results = database.dropBox(1, after: self.dateAdded, withAccess: access);

        if results.count == 0 {
            return nil;
        }

        return results[0];
    }

    public func previousItemInDropbox(access: SQLRead) -> TitleInstance? {
        var results = database.dropBox(1, before: self.dateAdded, withAccess: access);

        if results.count == 0 {
            return nil;
        }

        return results[0];
    }
}

private enum TagOrInstance : Hashable {
    case Template(tag: Tag)
    case Instance(instance: TagInstance)

    var hashValue: Int {
        get {
            switch (self) {
            case .Template(let tag):
                return tag.hashValue;
            case .Instance(let instance):
                return instance.hashValue;
            }
        }
    }

    static func create(o: AnyObject) -> TagOrInstance {
        if let instance = o as? TagInstance {
            return TagOrInstance.Instance(instance: instance);
        }
        else {
            return TagOrInstance.Template(tag: o as! Tag);
        }
    }

    func toInstance() -> TagInstance {
        switch (self) {
        case .Instance(let instance):
            return instance;
        default:
            assert(false);
        }
    }
}

public func == (o1: Tag, o2: TagInstance) -> Bool {
    return o1.id == o2.tag.id;
}

private func == (o1: TagOrInstance, o2: TagOrInstance) -> Bool {
    switch (o1) {
    case .Template(let t1):
        switch (o2) {
        case .Template(let t2):
            return t1 == t2;
        case .Instance(let i2):
            return t1 == i2;
        }
    case .Instance(let i1):
        switch (o2) {
        case .Template(let t2):
            return t2 == i1;
        case .Instance(let i2):
            return i1 == i2;
        }
    }
}

public extension Database {
    internal func fireTitleInstanceTagsChanged(titleInstance: TitleInstance, tags: [TagInstance]) {
        for delegate in delegates {
            delegate.titleInstanceTagsChanged(titleInstance, tags: tags);
        }

        updateShallowCopy(titleInstance);
    }

    internal func updateShallowCopy(titleInstance: TitleInstance) {
        handle.readAsync { access in
            do {
                let statement = try access.prepare("SELECT * FROM dad_tag_instance WHERE dad_title_instance_id = ?")
                var dump = [String: AnyObject]();

                dump["dad_title_instance_id"] = titleInstance.id;
                dump["dad_title_id"]          = titleInstance.title.id;
                dump["dad_title"]             = titleInstance.title.name;
                dump["duration"]              = titleInstance.duration;

                if let dateProduced = titleInstance.dateProduced {
                    dump["date_produced"] = dateProduced;
                }

                if let datePublished = titleInstance.datePublished {
                    dump["date_published"] = datePublished;
                }

                dump["date_added"]    = titleInstance.dateAdded;
                dump["date_modified"] = titleInstance.dateModified;

                var tags = [[String: AnyObject]]();

                try statement.bind(titleInstance.id, atIndex: 1)
                while try statement.step() {
                    var tag = [String: AnyObject]();

                    if let value = statement.columnString(0) {
                        tag["dad_tag_instance_id"] = value
                    }

                    if let value = statement.columnString(1) {
                        tag["dad_tag_id"] = value
                        tag["dad_tag"]    = try Tag.shared(value, fromDatabase: self, withAccess: access).name;
                    }

                    if let value = statement.columnDouble(6) as Double? {
                        tag["start"] = value
                    }

                    if let value = statement.columnDouble(7) as Double? {
                        tag["end"] = value
                    }

                    if let value = statement.columnString(8) {
                        tag["data"] = value
                    }

                    tags.append(tag);
                }

                dump["tags"] = tags;

                NSDictionary(dictionary: dump).writeToURL(titleInstance.url.URLByAppendingPathComponent("Info.plist"), atomically: true);
            }
            catch {
            }
        }
    }

    public func createTitleInstanceTable(access: SQLWrite) throws {
        let sql = "CREATE TABLE dad_title_instance(\n" +
            "  dad_title_instance_id VARCHAR(64) PRIMARY KEY,\n" +
            "  dad_title_id          VARCHAR(64) REFERENCES dad_title NOT NULL,\n" +
            "  duration              REAL NOT NULL,\n" +
            "  date_produced         REAL,\n" +
            "  date_published        REAL,\n" +
            "  date_added            REAL NOT NULL,\n" +
            "  date_modified         REAL NOT NULL\n" +
            ");";

        try access.exec(sql);
    }

    public func urlForTitleInstance(id: String, create: Bool = false) -> NSURL {
        let prefix = id[0...2];
        let suffix = id.suffix(start: 3);

        let firstPart = storageURL.URLByAppendingPathComponent(prefix, isDirectory: true);

        if create {
            if let path = firstPart.path {
                Darwin.mkdir(path, 0o755);
            }
        }

        let lastPart = firstPart.URLByAppendingPathComponent(suffix, isDirectory: true);

        if create {
            if let path = lastPart.path {
                Darwin.mkdir(path, 0o755);
            }
        }

        return lastPart;
    }
}
