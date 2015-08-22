//
//  TagInstance.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import SQL
import ExtraDataStructures

private let tagInstanceCache = ReferenceCache<String, TagInstance>();

public class TagInstance : Hashable, CustomStringConvertible {
    public let database: Database;
    public let id:       String;

    private var _tag: Tag;
    public var tag: Tag {
        get {
            return _tag;
        }
    }

    public func setTag(newValue: Tag, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET dad_tag_id = ? WHERE dad_tag_instance_id = ?")
        try statement.bind(newValue.id, atIndex: 1)
        try statement.bind(self.id,     atIndex: 2)
        try statement.step()
        _tag = tag;
    }

    private var _title: Title?;
    public var title: Title? {
        get {
            return _title;
        }
    }

    public func setTitle(newValue: Title?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET dad_title_id = ? WHERE dad_tag_instance_id = ?")

        if let title = newValue {
            try statement.bind(title.id, atIndex: 1)
        }
        
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _title = title;
    }

    private var _titleInstance: TitleInstance?;
    public var titleInstance: TitleInstance? {
        get {
            return _titleInstance;
        }
    }

    public func setTitleInstance(newValue: TitleInstance?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET dad_title_instance_id = ? WHERE dad_tag_instance_id = ?")

        if let titleInstance = newValue {
            try statement.bind(titleInstance.id, atIndex: 1)
        }
        
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _titleInstance = titleInstance;
    }

    private var _parentTag: Tag?;
    public var parentTag: Tag? {
        get {
            return _parentTag;
        }
    }

    public func setParentTag(newValue: Tag?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET dad_parent_tag_id = ? WHERE dad_tag_instance_id = ?")

        if let parentTag = newValue {
            try statement.bind(parentTag.id, atIndex: 1)
        }
        
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _parentTag = newValue;
    }

    private var _parentTagInstance: TagInstance?;
    public var parentTagInstance: TagInstance? {
        get {
            return _parentTagInstance;
        }
    }

    public func setParentTagInstance(newValue: TagInstance?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET dad_parent_tag_instance_id = ? WHERE dad_tag_instance_id = ?")

        if let parentTagInstance = newValue {
            try statement.bind(parentTagInstance.id, atIndex: 1)
        }
        
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _parentTagInstance = newValue;
    }

    private var _time: TimeRange?;
    public var time: TimeRange? {
        get {
            return _time;
        }
    }

    public func setTime(newValue: TimeRange?, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET start = ?, end = ? WHERE dad_tag_instance_id = ?")

        if let t = newValue {
            try statement.bind(t.start, atIndex: 1)
            try statement.bind(t.end,   atIndex: 2)
        }
        else {
            try statement.bindNull(1);
            try statement.bindNull(2);
        }

        try statement.bind(self.id,  atIndex: 3)
        try statement.step()
        _time = newValue;
    }

    private var _data: String?;
    public var data: String? {
        get {
            return _data;
        }
    }

    public var hashValue: Int {
        get {
            return id.hashValue;
        }
    }

    public var description: String {
        get {
            return tag.name;
        }
    }

    public func setData(newValue: String, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag_instance SET data = ? WHERE dad_tag_instance_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _data = newValue;
    }

    internal init(id: String, tag: Tag, title: Title?, titleInstance: TitleInstance?, parentTag: Tag?, parentTagInstance: TagInstance?, time: TimeRange?, data: String?, database: Database) {
        self.id                 = id;
        self._tag               = tag;
        self._title             = title;
        self._titleInstance     = titleInstance;
        self._parentTag         = parentTag;
        self._parentTagInstance = parentTagInstance;
        self._time              = time;
        self._data              = data;
        self.database           = database;
    }

    public convenience init(createWithTag tag: Tag, titleInstance: TitleInstance, inDatabase database: Database, withAccess access: SQLWrite) throws {
        try self.init(createWithTag: tag,
                              title: titleInstance.title,
                      titleInstance: titleInstance,
                          parentTag: nil,
                  parentTagInstance: nil,
                               time: nil,
                               data: nil,
                           database: database,
                         withAccess: access);
    }

    public init(createWithTag tag: Tag, title: Title?, titleInstance: TitleInstance?, parentTag: Tag?, parentTagInstance: TagInstance?, time: TimeRange?, data: String?, database: Database, withAccess access: SQLWrite) throws {
        self.id                 = Database.createNewID();
        self._tag               = tag;
        self._title             = title;
        self._titleInstance     = titleInstance;
        self._parentTag         = parentTag;
        self._parentTagInstance = parentTagInstance;
        self._time              = time;
        self._data              = data;
        self.database           = database;
        
        let statement = try access.prepare("INSERT INTO dad_tag_instance VALUES (?,?,?,?,?,?,?,?,?)");
        try statement.bind(self.id, atIndex: 1);
        try statement.bind(tag.id,  atIndex: 2);
        
        if let title = title {
            try statement.bind(title.id, atIndex: 3);
        }

        if let titleInstance = titleInstance {
            try statement.bind(titleInstance.id, atIndex: 4);
        }

        if let parentTag = parentTag {
            try statement.bind(parentTag.id, atIndex: 5);
        }

        if let parentTagInstance = parentTagInstance {
            try statement.bind(parentTagInstance.id, atIndex: 6);
        }

        if let t = time {
            try statement.bind(t.start, atIndex: 7);
            try statement.bind(t.end,   atIndex: 8);
        }
        else {
            try statement.bindNull(7);
            try statement.bindNull(8);
        }
        
        if let data = data {
            try statement.bind(data, atIndex: 9);
        }
        
        try statement.step();
        tagInstanceCache.getOrSet(self.id, value: self);
    }

    public class func optionalShared(id: String?, fromDatabase database: Database, withAccess access: SQLRead) -> TagInstance? {
        if let nnid = id {
            do {
                return try shared(nnid, fromDatabase: database, withAccess: access);
            }
            catch {
            }
        }
        
        return nil;
    }

    public class func shared(id: String, fromDatabase database: Database, withAccess access: SQLRead) throws -> TagInstance? {
        return try tagInstanceCache.get(id) {
            let statement = try access.prepare("SELECT * FROM dad_tag_instance WHERE dad_tag_instance_id = ?")
            try statement.bind(id, atIndex: 1);
            try statement.step();
            return try fromRow(id, statement: statement, fromDatabase: database, withAccess: access);
        }
    }
    
    public class func shared(statement: SQLStatement, fromDatabase database: Database, withAccess access: SQLRead) throws -> TagInstance {
        let id = statement.columnString(0)!;
        
        return try tagInstanceCache.get(id) {
            try fromRow(id, statement: statement, fromDatabase: database, withAccess: access);
        }
    }

    private class func fromRow(id: String, statement: SQLStatement, fromDatabase database: Database, withAccess access: SQLRead) throws -> TagInstance {
        let tag               = try Tag.shared(statement.columnString(1)!, fromDatabase: database, withAccess: access);
        let title             = Title.optionalShared(statement.columnString(2), fromDatabase: database, withAccess: access);
        let titleInstance     = TitleInstance.optionalShared(statement.columnString(3), fromDatabase: database, withAccess: access);
        let parentTag         = Tag.optionalShared(statement.columnString(4), fromDatabase: database, withAccess: access);
        let parentTagInstance = TagInstance.optionalShared(statement.columnString(5), fromDatabase: database, withAccess: access);
        let start: NSTimeInterval? = statement.columnDouble(6);
        let end:   NSTimeInterval? = statement.columnDouble(7);

        var time: TimeRange?;

        if let start = start, let end = end {
            time = TimeRange(start: start, end: end);
        }

        return TagInstance(
            id:                id,
            tag:               tag,
            title:             title,
            titleInstance:     titleInstance,
            parentTag:         parentTag,
            parentTagInstance: parentTagInstance,
            time:              time,
            data:              statement.columnString(8),
            database:          database);
    }

    public func delete(access: SQLWrite) throws -> Void {
        try access.exec("DELETE FROM dad_tag_instance WHERE dad_tag_instance_id = '\(self.id)'")
    }
}

public extension TitleInstance {
    public func files(access: SQLRead) throws -> [TagInstance] {
        let statement = try access.prepare("SELECT * FROM dad_tag_instance WHERE dad_tag_id = ? AND dad_title_instance_id = ? ORDER BY start")
        try statement.bind(StandardTagID.File.rawValue, atIndex: 1);
        try statement.bind(self.id, atIndex: 2);

        var f = [TagInstance]();
            
        while try statement.step() {
            f.append(try TagInstance.shared(statement, fromDatabase: self.database, withAccess: access));
        }
            
        return f;
    }

    public func filesURL(access: SQLRead) throws -> [NSURL] {
        return try files(access).map { return self.url.URLByAppendingPathComponent($0.data!) }
    }
}

public func == (ti1: TagInstance, ti2: TagInstance) -> Bool {
    return ti1.id == ti2.id;
}

public extension Database {
    public func createTagInstanceTable(access: SQLWrite) throws {
        let sql = "CREATE TABLE dad_tag_instance(\n" +
            "  dad_tag_instance_id        VARCHAR(64)  PRIMARY KEY,\n" +
            "  dad_tag_id                 VARCHAR(64)  REFERENCES dad_tag NOT NULL,\n" +
            "  dad_title_id               VARCHAR(64)  REFERENCES dad_title,\n" +
            "  dad_title_instance_id      VARCHAR(64)  REFERENCES dad_title_instance,\n" +
            "  dad_parent_tag_id          VARCHAR(64)  REFERENCES dad_title_instance (dad_title_id),\n" +
            "  dad_parent_tag_instance_id VARCHAR(64)  REFERENCES dad_tag_instance   (dad_tag_instance_id),\n" +
            "  start                      REAL,\n" +
            "  end                        REAL,\n" +
            "  data                       TEXT\n" +
            ");";

        try access.exec(sql);
    }

    public func dropBox(maxResults: Int, block: ([TitleInstance]) -> Void) -> Void {
        handle.readAsync { (access: SQLRead) in
            do {
                let dropBoxSQL =
                    "SELECT dad_title_instance_id " +
                    "FROM   dad_tag_instance " +
                    "WHERE  dad_title_instance_id IS NOT NULL AND " +
                    "       dad_tag_id = '\(StandardTagID.DropBox.rawValue)' " +
                    "LIMIT  \(maxResults)";

                let sql = "SELECT   * " +
                          "FROM     dad_title_instance " +
                          "WHERE    dad_title_instance_id IN (\(dropBoxSQL)) " +
                          "ORDER BY date_added";

                let statement = try access.prepare(sql);
                var results   = [TitleInstance]();

                while try statement.step() {
                    do {
                        results.append(try TitleInstance.shared(statement, fromDatabase: self, withAccess: access));
                    }
                    catch {
                    }
                }

                block(results);
            }
            catch {
                block([]);
            }
        }
    }
}
