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

public class TagInstance {
    public let database:          Database;
    public let id:                String;

    private var _tag: Tag;
    public var tag: Tag {
        get {
            return _tag;
        }
    }

    public func setTag(newValue: Tag) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET dad_tag_id = ? WHERE dad_tag_instance_id = ?")
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

    public func setTitle(newValue: Title?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET dad_title_id = ? WHERE dad_tag_instance_id = ?")

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

    public func setTitleInstance(newValue: TitleInstance?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET dad_title_instance_id = ? WHERE dad_tag_instance_id = ?")

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

    public func setParentTag(newValue: Tag?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET dad_parent_tag_id = ? WHERE dad_tag_instance_id = ?")

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

    public func setParentTagInstance(newValue: TagInstance?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET dad_parent_tag_instance_id = ? WHERE dad_tag_instance_id = ?")

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

    public func setTime(newValue: TimeRange?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET start = ?, end = ? WHERE dad_tag_instance_id = ?")

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

    public func setData(newValue: String) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_tag_instance SET data = ? WHERE dad_tag_instance_id = ?")
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

    public init(createWithTag tag: Tag, title: Title?, titleInstance: TitleInstance?, parentTag: Tag?, parentTagInstance: TagInstance?, time: TimeRange?, data: String?, database: Database) throws {
        database.assertInTransaction();

        self.id                 = Database.createNewID();
        self._tag               = tag;
        self._title             = title;
        self._titleInstance     = titleInstance;
        self._parentTag         = parentTag;
        self._parentTagInstance = parentTagInstance;
        self._time              = time;
        self._data              = data;
        self.database           = database;
        
        let statement = try database.handle!.prepare("INSERT INFO dad_tag_instance VALUES (?,?,?,?,?,?,?,?,?)");
        
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
    }

    public class func optionalShared(id: String?, fromDatabase database: Database) throws -> TagInstance? {
        if let nnid = id {
            return try shared(nnid, fromDatabase: database);
        }
        
        return nil;
    }

    public class func shared(id: String, fromDatabase database: Database) throws -> TagInstance? {
        return try tagInstanceCache.get(id) {
            try database.exec("SELECT * FROM dad_tag_instance WHERE dad_tag_instance_id = ?") { (statement: SQLStatement) in
                try statement.bind(id, atIndex: 1);
                try statement.step();
                return try fromRow(id, statement: statement, fromDatabase: database);
            }
        }
    }
    
    public class func shared(statement: SQLStatement, fromDatabase database: Database) throws -> TagInstance {
        let id = statement.columnString(0)!;
        
        return try tagInstanceCache.get(id) {
            try fromRow(id, statement: statement, fromDatabase: database);
        }
    }

    private class func fromRow(id: String, statement: SQLStatement, fromDatabase database: Database) throws -> TagInstance {
        let tag               = try Tag.shared(statement.columnString(1)!, fromDatabase: database);
        let title             = try Title.optionalShared(statement.columnString(2), fromDatabase: database);
        let titleInstance     = try TitleInstance.optionalShared(statement.columnString(3), fromDatabase: database);
        let parentTag         = try Tag.optionalShared(statement.columnString(4), fromDatabase: database);
        let parentTagInstance = try TagInstance.optionalShared(statement.columnString(5), fromDatabase: database);
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
}

public extension TitleInstance {
    public func files() throws -> [TagInstance] {
        return try database.exec("SELECT * FROM dad_tag_instance WHERE dad_tag_id = ? AND dad_title_instance_id = ? ORDER BY start") { (statement: SQLStatement) in
            try statement.bind(StandardTagID.File.rawValue, atIndex: 1);
            try statement.bind(self.id, atIndex: 2);
            
            var f = [TagInstance]();
            
            while try statement.step() {
                f.append(try TagInstance.shared(statement, fromDatabase: self.database));
            }
            
            return f;
        }
    }
}

public extension Database {
    public func createTagInstanceTable(handle: SQLDatabase) throws {
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

        try handle.exec(sql);
    }
}
