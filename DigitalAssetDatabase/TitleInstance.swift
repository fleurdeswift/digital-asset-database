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
    public var fileName: String;
    public var duration: Double;
}

private let titleInstanceCache = ReferenceCache<String, TitleInstance>();

public class TitleInstance {
    public let database: Database;
    public let id:       String;

    private var _title: Title?;
    public var title: Title? {
        get {
            return _title;
        }
    }

    private func setTitle(newValue: Title?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_title_instance SET dad_title_id = ? WHERE dad_title_instance_id = ?")

        if let title = newValue {
            try statement.bind(title.id, atIndex: 1)
        }
        
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

    private func setDuration(newValue: NSTimeInterval) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_title_instance SET duration = ? WHERE dad_title_instance_id = ?")
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

    public func setDateProduced(newValue: NSTimeInterval?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_title_instance SET date_produced = ? WHERE dad_title_instance_id = ?")
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

    private func setDatePublished(newValue: NSTimeInterval?) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_title_instance SET date_published = ? WHERE dad_title_instance_id = ?")
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

    private func setDateModified(newValue: NSTimeInterval) throws {
        database.assertInTransaction();
        let statement = try self.database.handle!.prepare("UPDATE dad_title_instance SET date_modified = ? WHERE dad_title_instance_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _dateModified = newValue;
    }

    public init(createWithFiles files: [TitleInstanceFile], tags: [Tag]?, title: Title?, inDatabase database: Database) throws {
        database.assertInTransaction();

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
            realTitle = try Title(createWithName: "", inDatabase: database);
        }

        let handle = database.handle!;
        var statement = try handle.prepare("INSERT INTO dad_title_instance (dad_title_instance_id, dad_title_id, duration, date_added, date_modified) VALUES (?,?,?,?,?)")
        
        try statement.bind(self.id,      atIndex: 1);
        try statement.bind(realTitle.id, atIndex: 2);
        try statement.bind(duration,     atIndex: 3);
        try statement.bind(now,          atIndex: 4);
        try statement.bind(now,          atIndex: 5);
        try statement.step();

        statement = try handle.prepare("INSERT INTO dad_tag_instance (dad_tag_instance_id, dad_tag_id, dad_title_id, dad_title_instance_id, start, end, data) VALUES (?,?,?,?,?,?,?)")
        
        try statement.bind(StandardTagID.File.rawValue, atIndex: 2);
        try statement.bind(realTitle.id,                atIndex: 3);
        try statement.bind(self.id,                     atIndex: 4);

        var current: Double = 0;
        
        for file in files {
            let tagInstanceID = Database.createNewID();
            
            try statement.bind(tagInstanceID, atIndex: 1);
            try statement.bind(current,       atIndex: 5);
            current += file.duration;
            try statement.bind(current,       atIndex: 6);
            try statement.bind(file.fileName, atIndex: 7);
            try statement.step();
            try statement.reset();
        }

        if let tags = tags {
            for tag in tags {
                let tagInstanceID = Database.createNewID();
            
                try statement.bind(tagInstanceID, atIndex: 1);
                try statement.bind(tag.id,        atIndex: 2);
                try statement.bindNull(5); // start
                try statement.bindNull(6); // end
                try statement.bindNull(7); // data
                try statement.step();
                try statement.reset();
            }
        }

        titleInstanceCache.getOrSet(self.id, value: self)
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
    
    public class func optionalShared(id: String?, fromDatabase database: Database) throws -> TitleInstance? {
        if let nnid = id {
            return try shared(nnid, fromDatabase: database);
        }
        
        return nil;
    }
    
    public class func shared(statement: SQLStatement, fromDatabase database: Database) throws -> TitleInstance {
        let id    = statement.columnString(0)!;
        let title = try Title.shared(statement.columnString(1)!, fromDatabase: database);
        
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
    
    public class func shared(id: String, fromDatabase database: Database) throws -> TitleInstance {
        return try titleInstanceCache.get(id) {
            return try database.exec("SELECT * FROM dad_title_instance WHERE dad_title_instance_id = ?") { (statement: SQLStatement) in
                try statement.bind(id, atIndex: 1);
                try statement.step()
                return try shared(statement, fromDatabase: database);
            }
        }
    }
}

public extension Database {
    public func createTitleInstanceTable(handle: SQLDatabase) throws {
        let sql = "CREATE TABLE dad_title_instance(\n" +
            "  dad_title_instance_id VARCHAR(64) PRIMARY KEY,\n" +
            "  dad_title_id          VARCHAR(64) REFERENCES dad_title NOT NULL,\n" +
            "  duration              REAL NOT NULL,\n" +
            "  date_produced         REAL,\n" +
            "  date_published        REAL,\n" +
            "  date_added            REAL NOT NULL,\n" +
            "  date_modified         REAL NOT NULL\n" +
            ");";

        try handle.exec(sql);
    }
}
