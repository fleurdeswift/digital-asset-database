//
//  Title.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import ExtraDataStructures
import SQL

private let titleCache = ReferenceCache<String, Title>();

public class Title {
    public let database: Database;
    public let id: String;

    private var _name: String;
    public var name: String {
        get {
            return _name;
        }
    }

    internal func setName(newValue: String, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_title SET name = ? WHERE dad_title_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id,  atIndex: 2)
        try statement.step()
        self._name = newValue;
    }

    internal class func create(id: String, name: String, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("INSERT INTO dad_title VALUES(?,?);")
        try statement.bind(id,   atIndex: 1);
        try statement.bind(name, atIndex: 2);
        try statement.step();
    }

    public init(createWithName name: String, inDatabase database: Database, withAccess access: SQLWrite) throws {
        self.database = database;
        self.id       = Database.createNewID();
        self._name    = name;

        try Title.create(self.id, name: name, withAccess: access);
        titleCache.getOrSet(self.id, value: self);
    }

    internal init(id: String, name: String, fromDatabase database: Database) {
        self.database = database;
        self.id       = id;
        self._name    = name;
    }
    
    public class func optionalShared(id: String?, fromDatabase database: Database, withAccess access: SQLRead) -> Title? {
        if let nnid = id {
            do {
                return try Title.shared(nnid, fromDatabase: database, withAccess: access);
            }
            catch {
            }
        }
        
        return nil;
    }
    
    public class func shared(id: String, name: String, fromDatabase database: Database) -> Title {
        return titleCache.get(id) {
            return Title(id: id, name: name, fromDatabase: database);
        }
    }

    public class func shared(id: String, fromDatabase database: Database, withAccess access: SQLRead) throws -> Title {
        return try titleCache.get(id) {
            let statement = try access.prepare("SELECT dad_name from dad_title WHERE dad_id = ?")
            try statement.bind(id, atIndex: 1);
            try statement.step()
            return Title(id: id, name: statement.columnString(0)!, fromDatabase: database);
        }
    }
    
    public func instances(access: SQLRead) throws -> [TitleInstance] {
        let statement = try access.prepare("SELECT * FROM dad_title_instance WHERE dad_title_id = ?")
        var i = [TitleInstance]();
        
        try statement.bind(self.id, atIndex: 1);
        while try statement.step() {
            i.append(try TitleInstance.shared(statement, fromDatabase: self.database, withAccess: access));
        }
            
        return i;
    }
}

public extension Database {
    public func findTitles(title: String, withAccess access: SQLRead, block: (titles: [Title]) -> Void) {
        do {
            let s = try access.prepare("SELECT * FROM dad_title WHERE name LIKE ?")
            try s.bind(title.asLikeClause, atIndex: 1);
            
            var titles = [Title]();
            
            while try s.step() {
                titles.append(Title.shared(s.columnString(0)!, name: s.columnString(1)!, fromDatabase: self));
            }
            
            block(titles: titles);
        }
        catch {
            block(titles: []);
        }
    }
    
    public func createTitleTable(access: SQLWrite) throws {
        try access.exec(
            "CREATE TABLE dad_title(\n" +
            "  dad_title_id VARCHAR(64)  PRIMARY KEY,\n" +
            "  name         VARCHAR(256) NOT NULL\n" +
            ");");
    }
}
