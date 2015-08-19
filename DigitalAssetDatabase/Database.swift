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
    internal(set) public var handle: SQLQueuedDatabase!;
    internal(set) public var schemaVersion: Int = 0;
    internal(set) public var queue: dispatch_queue_t = dispatch_queue_create("Database", DISPATCH_QUEUE_CONCURRENT);
    
    public init(path: String) throws {
        self.handle = try SQLQueuedDatabase(filename: path, flags: SQL.SQL_OPEN_READWRITE | SQL.SQL_OPEN_URI | SQL.SQL_OPEN_CREATE | SQL.SQL_OPEN_FULLMUTEX, vfs: nil);

        do {
            try handle.read { (access: SQLRead) throws in
                let statement = try access.prepare("SELECT value FROM dad_config WHERE name = 'SCHEMA_VERSION';");
            
                while try statement.step() {
                    self.schemaVersion = statement.columnInt(0);
                }
            }
        }
        catch {
            try handle.write { (access: SQLWrite) throws in
                try self.createSchema(access);
            }
        }
    }

    internal func createSchema(access: SQLWrite) throws {
        try access.exec("CREATE TABLE dad_config(\n" +
            "  name  VARCHAR(64) PRIMARY KEY,\n" +
            "  value VARCHAR(256)\n" +
            ");");
        
        try access.exec("INSERT INTO dad_config VALUES ('SCHEMA_VERSION', '1');");

        try createTitleTable(access);
        try createTitleInstanceTable(access);
        try createTagTable(access);
        try createTagInstanceTable(access);

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
