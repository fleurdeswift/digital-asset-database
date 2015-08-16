//
//  Database.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import SQL
import Darwin
import ExtraDataStructures

public protocol DatabaseDelegate : class {
    func tagAdded(tag: Tag);
    func tagNameChanged(tag: Tag);
    func tagTypeChanged(tag: Tag, oldType: String);
}

public class Database {
    internal(set) public var handle: SQLDatabase?;
    internal(set) public var schemaVersion: Int = 0;
    internal(set) public var queue: dispatch_queue_t = dispatch_queue_create("Database", DISPATCH_QUEUE_CONCURRENT);
    
    public init(path: String) throws {
        handle = nil
        
        let database = try SQLDatabase(filename: path, flags: SQL.SQL_OPEN_READWRITE | SQL.SQL_OPEN_URI | SQL.SQL_OPEN_CREATE | SQL.SQL_OPEN_FULLMUTEX, vfs: nil);
        
        handle = database;
        
        do {
            let statement = try database.prepare("SELECT value FROM dad_config WHERE name = 'SCHEMA_VERSION';");
            
            while try statement.step() {
                schemaVersion = statement.columnInt(0);
            }
        }
        catch {
            try createSchema();
        }
    }
    
    public func exec(sql: String, block: (statement: SQLStatement) throws -> Void) throws -> Void {
        try handle!.exec(queue, sql: sql, block: block);
    }
    
    public func exec<T>(sql: String, block: (statement: SQLStatement) throws -> T) throws -> T {
        return try handle!.exec(queue, sql: sql, block: block);
    }

    public func exec<T>(sql: String, block: (statement: SQLStatement) throws -> T?) throws -> T? {
        return try handle!.exec(queue, sql: sql, block: block);
    }
    
    public func createSchema() throws {
        try handle!.exec("BEGIN EXCLUSIVE TRANSACTION;");

        try handle!.exec("CREATE TABLE dad_config(\n" +
            "  name  VARCHAR(64) PRIMARY KEY,\n" +
            "  value VARCHAR(256)\n" +
            ");");
        
        try handle!.exec("INSERT INTO dad_config VALUES ('SCHEMA_VERSION', '1');");

        try createTitleTable(handle!);
        try createTitleInstanceTable(handle!);
        try createTagTable(handle!);
        try createTagInstanceTable(handle!);
        try handle!.exec("COMMIT TRANSACTION;");
        
        schemaVersion = 1;
    }
    
    private class func hex() -> String {
        return arc4random().asHexString;
    }
    
    public class func createNewID() -> String {
        return hex() + hex() + hex() + hex() + hex() + hex() + hex() + hex()
    }
    
    internal var delegates = [DatabaseDelegate]();
    
    public func addDelegate(delegate: DatabaseDelegate, strong: Bool) {
        dispatch_sync(queue) {
            self.delegates.append(delegate);
        }
    }
    
    public func removeDelegate(delegate: DatabaseDelegate) {
        dispatch_sync(queue) {
            self.delegates = self.delegates.filter { return $0 !== delegate };
        }
    }
}
