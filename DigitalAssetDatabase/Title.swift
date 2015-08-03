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

    public var name: String {
        willSet {
            database.transactionAsync {
                let statement = try self.database.handle!.prepare("UPDATE dad_title SET name = ? WHERE dad_title_id = ?")
                try statement.bind(newValue, atIndex: 1)
                try statement.bind(self.id, atIndex: 2)
                try statement.step()
            };
        }
    }

    public init(createWithName name: String, inDatabase database: Database) throws {
        self.database = database;
        self.id       = Database.createNewID();
        self.name     = name;

        try database.transaction {
            let statement = try database.handle!.prepare("INSERT INTO dad_title VALUES(?,?);")
            try statement.bind(self.id,   atIndex: 1);
            try statement.bind(self.name, atIndex: 2);
            try statement.step();
        }
        
        titleCache.getOrSet(self.id, value: self);
    }
    
    internal init(id: String, name: String, fromDatabase database: Database) {
        self.database = database;
        self.id       = id;
        self.name     = name;
    }
    
    public class func optionalShared(id: String?, fromDatabase database: Database) throws -> Title? {
        if let nnid = id {
            return try Title.shared(nnid, fromDatabase: database);
        }
        
        return nil;
    }
    
    public class func shared(id: String, name: String, fromDatabase database: Database) -> Title {
        return titleCache.get(id) {
            return Title(id: id, name: name, fromDatabase: database);
        }
    }

    public class func shared(id: String, fromDatabase database: Database) throws -> Title {
        return try titleCache.get(id) {
            return try database.exec("SELECT dad_name from dad_title WHERE dad_id = ?") { (statement: SQLStatement) in
                try statement.bind(id, atIndex: 1);
                try statement.step()
                return Title(id: id, name: statement.columnString(0)!, fromDatabase: database);
            }
        }
    }
    
    public func instances() throws -> [TitleInstance] {
        return try database.exec("SELECT * FROM dad_title_instance WHERE dad_title_id = ?") { (statement: SQLStatement) in
            var i = [TitleInstance]();
        
            try statement.bind(self.id, atIndex: 1);
            while try statement.step() {
                i.append(try TitleInstance.shared(statement, fromDatabase: self.database));
            }
            
            return i;
        }
    }
}

public extension Database {
    public func findTitles(title: String, block: (titles: [Title]) -> Void) {
        dispatch_async(queue) {
            do {
                let s = try self.handle!.prepare("SELECT * FROM dad_title WHERE name LIKE ?")
                try s.bind(title.asLikeClause, atIndex: 1);
                
                var titles = [Title]();
                
                while try s.step() {
                    titles.append(Title.shared(s.columnString(0)!, name: s.columnString(1)!, fromDatabase: self));
                }
                
                block(titles: titles);
            }
            catch {
            }
        }
    }
    
    public func createTitleTable(handle: SQLDatabase) throws {
        try handle.exec(
            "CREATE TABLE dad_title(\n" +
            "  dad_title_id VARCHAR(64)  PRIMARY KEY,\n" +
            "  name         VARCHAR(256) NOT NULL\n" +
            ");");
    }
}
