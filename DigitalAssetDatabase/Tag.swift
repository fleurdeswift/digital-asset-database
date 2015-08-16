//
//  Tag.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import ExtraDataStructures
import SQL

public enum TagType : String {
    case Special     = "e5c08216588a2b08c48fcd78b646616e84ecfd485cd7343d869ae4cf624520b7"

    // Title / Title Instance tag types.
    case Serie       = "f905414ec09500e4149824b20a453a37e816d3f530b09b2353183b736622d258"
    case Rating      = "8a79bbc437b78c1b21c0f1f56e2cdf92a0464e7034ea3a233445e86bf9667ae3"
    
    // Scene tag types
    case Person      = "e47fb7cbdad3f96e6bd70dcdb14a1bf231659cd8d290f3768d1b7f826d9dbab2"
    case Action      = "3580469d06f361ee17533bb26995d8874a57f3545d26d63cc140f3f1c4de47ff"
    case Nationality = "05130773a9e1714b1d51642fee19af5e4b3c692714adac1e44e8342a21d6e4ba"
    case Set         = "577fba0b80d791636e583ebc868cf72baf53b9c32e18d501355f2a4fca8820cd"
    
    // Composed
    case Recents     = "d5d42c012481a0899056b6b73d10e3174049ebd4270452cf0793ca189f35205e"
    case Favorites   = "5aa5c2e0971046cba57610c20d296d459210a3d7f241dd3a70b562933de292bd"
    
    public var localizedName: String {
        get {
            switch (self) {
            case .Special:     return NSLocalizedString("Special",     comment: "");
            case .Serie:       return NSLocalizedString("Serie",       comment: "");
            case .Rating:      return NSLocalizedString("Rating",      comment: "");
            case .Person:      return NSLocalizedString("Person",      comment: "");
            case .Action:      return NSLocalizedString("Action",      comment: "");
            case .Nationality: return NSLocalizedString("Nationality", comment: "");
            case .Set:         return NSLocalizedString("Set",         comment: "");
            case .Favorites:   return NSLocalizedString("Favorites",   comment: "");
            case .Recents:     return NSLocalizedString("Recents",     comment: "");
            //default:           return self.rawValue;
            }
        }
    }
}

public enum StandardTagID : String {
    case File  = "991ab620f9caaa639a8547d593aa82d445121e687889fc3c7c7afc8b22c6ee22"
    case Scene = "ccdcda42124d564fef6d24ca4326bec84e8f660b392f03c299130122bf2f5de8"
}

private let tagCache = ReferenceCache<String, Tag>();

public class Tag {
    public let database: Database;
    public let id: String;
    
    public var name: String {
        willSet {
            database.transactionAsync {
                let statement = try self.database.handle!.prepare("UPDATE dad_tag SET name = ? WHERE dad_tag_id = ?")
                try statement.bind(newValue, atIndex: 1)
                try statement.bind(self.id, atIndex: 2)
                try statement.step()
            };
        }
        
        didSet {
            self.database.fireTagNameChanged(self);
        }
    }
    
    public var type: String {
        willSet {
            database.transactionAsync {
                let statement = try self.database.handle!.prepare("UPDATE dad_tag SET type = ? WHERE dad_tag_id = ?")
                try statement.bind(newValue, atIndex: 1)
                try statement.bind(self.id, atIndex: 2)
                try statement.step()
            };
        }
        
        didSet {
            self.database.fireTagTypeChanged(self, oldType: oldValue);
        }
    }

    public var searchable: Bool {
        willSet {
            database.transactionAsync {
                let statement = try self.database.handle!.prepare("UPDATE dad_tag SET searchable = ? WHERE dad_tag_id = ?")
                try statement.bind(newValue, atIndex: 1)
                try statement.bind(self.id, atIndex: 2)
                try statement.step()
            };
        }
    }
    
    public init(createWithName name: String, type: String, searchable: Bool, inDatabase database: Database) throws {
        self.database   = database;
        self.id         = Database.createNewID();
        self.name       = name;
        self.type       = type;
        self.searchable = searchable;

        try database.transaction {
            let statement = try database.handle!.prepare("INSERT INTO dad_tag VALUES(?,?,?,?);")
            try statement.bind(self.id,         atIndex: 1);
            try statement.bind(self.name,       atIndex: 2);
            try statement.bind(self.type,       atIndex: 3);
            try statement.bind(self.searchable, atIndex: 2);
            try statement.step();
        }
        
        tagCache.getOrSet(self.id, value: self);
    }
    
    internal init(id: String, name: String, type: String, searchable: Bool, fromDatabase database: Database) {
        self.database   = database;
        self.id         = id;
        self.name       = name;
        self.type       = type;
        self.searchable = searchable;
    }
    
    public class func optionalShared(id: String?, fromDatabase database: Database) throws -> Tag? {
        if let nnid = id {
            return try Tag.shared(nnid, fromDatabase: database);
        }
        
        return nil;
    }

    public class func shared(statement: SQLStatement, fromDatabase database: Database) -> Tag {
        let id = statement.columnString(0)!;
        return tagCache.get(id) {
            return Tag(
                id:           id,
                name:         statement.columnString(1)!,
                type:         statement.columnString(2)!,
                searchable:   statement.columnBool(3)!,
                fromDatabase: database);
        }
    }
    
    public class func shared(id: String, fromDatabase database: Database) throws -> Tag {
        return try tagCache.get(id) {
            return try database.exec("SELECT name, type, searchable from dad_tag WHERE dad_tag_id = ?") { (statement: SQLStatement) in
                try statement.bind(id, atIndex: 1);
                try statement.step()
                return Tag(
                    id:           id,
                    name:         statement.columnString(0)!,
                    type:         statement.columnString(1)!,
                    searchable:   statement.columnBool(2)!,
                    fromDatabase: database);
            }
        }
    }
}

public extension Database {
    internal func fireTagNameChanged(tag: Tag) {
        for delegate in delegates {
            delegate.tagNameChanged(tag);
        }
    }

    internal func fireTagTypeChanged(tag: Tag, oldType: String) {
        for delegate in delegates {
            delegate.tagTypeChanged(tag, oldType: oldType);
        }
    }

    public func addTag(name: String, type: TagType) throws -> Tag {
        let newTag = try handle!.transaction(queue) { () throws -> (id: String, created: Bool) in
            do {
                let s = try self.handle!.prepare("SELECT dad_tag_id FROM dad_tag WHERE name = ? AND type = ?")
                try s.bind(name, atIndex: 1);
                try s.bind(type.rawValue, atIndex: 2);
                
                if try s.step() {
                    return (s.columnString(0)!, false);
                }
            }
            
            var newID = (type.rawValue + "." + name).sha256();
            
            do {
                let s = try self.handle!.prepare("INSERT INTO dad_tag VALUES (?, ?, ?, 1);");
                try s.bind(newID, atIndex: 1);
                try s.bind(name, atIndex: 2);
                try s.bind(type.rawValue, atIndex: 3);
                try s.step();
            }
            catch SQLError.Constraint {
                newID = Database.createNewID();

                let s = try self.handle!.prepare("INSERT INTO dad_tag VALUES (?, ?, ?, 1);");
                try s.bind(newID, atIndex: 1);
                try s.bind(name, atIndex: 2);
                try s.bind(type.rawValue, atIndex: 3);
                try s.step();
            }

            return (newID, true);
        };
        
        let tag = try Tag.shared(newTag.id, fromDatabase: self);

        if newTag.created {
            for delegate in delegates {
                delegate.tagAdded(tag);
            }
        }
        
        return tag;
    }

    public func findTags(type type: TagType, block: (tags: [Tag]) -> Void) -> Void {
        return findTags(type: type.rawValue, block: block);
    }
    
    public func findTags(type type: String, block: (tags: [Tag]) -> Void) -> Void {
        dispatch_async(queue) {
            do {
                let s = try self.handle!.prepare("SELECT * FROM dad_tag WHERE type = ? ORDER BY name COLLATE NOCASE")
                try s.bind(type, atIndex: 1);
                
                var tags = [Tag]();
                while try s.step() {
                    tags.append(Tag.shared(s, fromDatabase: self));
                }
                
                block(tags: tags);
            }
            catch {
            }
        }
    }
    
    public func findTags(title title: String, block: (tags: [Tag]) -> Void) -> Void {
        dispatch_async(queue) {
            do {
                let s = try self.handle!.prepare("SELECT * FROM dad_tag WHERE name LIKE ?")
                try s.bind(title.asLikeClause, atIndex: 1);
                
                var tags = [Tag]();
                while try s.step() {
                    tags.append(Tag.shared(s, fromDatabase: self));
                }
                
                block(tags: tags);
            }
            catch {
            }
        }
    }

    public func createTagTable(handle: SQLDatabase) throws {
        let sql = "CREATE TABLE dad_tag(\n" +
            "  dad_tag_id            VARCHAR(64)  PRIMARY KEY,\n" +
            "  name                  VARCHAR(256) NOT NULL,\n" +
            "  type                  VARCHAR(64)  NOT NULL,\n" +
            "  searchable            INTEGER      DEFAULT 1\n" +
            ");";

        try handle.exec(sql);
        try handle.exec("INSERT INTO dad_tag VALUES ('\(StandardTagID.File.rawValue)', 'FILE', '\(TagType.Special.rawValue)', 0);");
        try handle.exec("INSERT INTO dad_tag VALUES ('\(StandardTagID.Scene.rawValue)', 'SCENE', '\(TagType.Special.rawValue)', 0);");
    }
}
