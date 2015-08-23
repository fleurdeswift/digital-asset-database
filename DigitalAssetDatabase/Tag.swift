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
    case Special      = "e5c08216588a2b08c48fcd78b646616e84ecfd485cd7343d869ae4cf624520b7"
    case Unclassified = "1372a3810da5224a8d1007de41ff5f9bc16030f824f09ed65e954e00a1ade1a6"

    // Title / Title Instance tag types.
    case Serie        = "f905414ec09500e4149824b20a453a37e816d3f530b09b2353183b736622d258"
    case Rating       = "8a79bbc437b78c1b21c0f1f56e2cdf92a0464e7034ea3a233445e86bf9667ae3"
    
    // Scene tag types
    case Person       = "e47fb7cbdad3f96e6bd70dcdb14a1bf231659cd8d290f3768d1b7f826d9dbab2"
    case Action       = "3580469d06f361ee17533bb26995d8874a57f3545d26d63cc140f3f1c4de47ff"
    case Nationality  = "05130773a9e1714b1d51642fee19af5e4b3c692714adac1e44e8342a21d6e4ba"
    case Set          = "577fba0b80d791636e583ebc868cf72baf53b9c32e18d501355f2a4fca8820cd"
    
    // Composed
    case Recents      = "d5d42c012481a0899056b6b73d10e3174049ebd4270452cf0793ca189f35205e"
    case Favorites    = "5aa5c2e0971046cba57610c20d296d459210a3d7f241dd3a70b562933de292bd"
    
    public var localizedName: String {
        get {
            switch (self) {
            case .Special:       return NSLocalizedString("Special",       comment: "");
            case .Serie:         return NSLocalizedString("Serie",         comment: "");
            case .Rating:        return NSLocalizedString("Rating",        comment: "");
            case .Person:        return NSLocalizedString("Person",        comment: "");
            case .Action:        return NSLocalizedString("Action",        comment: "");
            case .Nationality:   return NSLocalizedString("Nationality",   comment: "");
            case .Set:           return NSLocalizedString("Set",           comment: "");
            case .Favorites:     return NSLocalizedString("Favorites",     comment: "");
            case .Recents:       return NSLocalizedString("Recents",       comment: "");
            case .Unclassified:  return NSLocalizedString("Unclassified",  comment: "");
            //default:           return self.rawValue;
            }
        }
    }
}

public enum StandardTagID : String {
    case File    = "991ab620f9caaa639a8547d593aa82d445121e687889fc3c7c7afc8b22c6ee22"
    case Scene   = "ccdcda42124d564fef6d24ca4326bec84e8f660b392f03c299130122bf2f5de8"
    case DropBox = "9753d4438475ac2d6d620b6f7ccdb96f1ddef9d97e8a7c10872c5c93bd121e29"
    case Preview = "324b134f57c70c729ae3dc4d298bb451656717d70523e942c1ce667b8024ea07"
}

public let StandardTagIDs = "'\(StandardTagID.File.rawValue)','\(StandardTagID.Scene.rawValue)','\(StandardTagID.Preview.rawValue)'"
private let tagCache = ReferenceCache<String, Tag>();

public class Tag : CustomStringConvertible, Hashable {
    public let database: Database;
    public let id: String;

    private var _name: String;
    public var name: String {
        get {
            return _name;
        }
    }

    public func setName(newValue: String, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag SET name = ? WHERE dad_tag_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        self._name = newValue;
        self.database.fireTagNameChanged(self);
    }

    private var _type: String;
    public var type: String {
        get {
            return _type;
        }
    }

    public func setType(newValue: String, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag SET type = ? WHERE dad_tag_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        let oldValue = _type;
        _type = newValue;
        self.database.fireTagTypeChanged(self, oldType: oldValue);
    }

    private var _searchable: Bool;
    public var searchable: Bool {
        get {
            return _searchable;
        }
    }

    public func setSearchable(newValue: Bool, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("UPDATE dad_tag SET searchable = ? WHERE dad_tag_id = ?")
        try statement.bind(newValue, atIndex: 1)
        try statement.bind(self.id, atIndex: 2)
        try statement.step()
        _searchable = newValue;
    }

    public var hashValue: Int {
        get {
            return id.hashValue;
        }
    }

    public init(createWithName name: String, type: String, searchable: Bool, inDatabase database: Database, withAccess access: SQLWrite) throws {
        self.database    = database;
        self.id          = Database.createNewID();
        self._name       = name;
        self._type       = type;
        self._searchable = searchable;

        try Tag.create(id, name: name, type: type, searchable: searchable, withAccess: access);
        tagCache.getOrSet(self.id, value: self);
    }
    
    internal init(id: String, name: String, type: String, searchable: Bool, fromDatabase database: Database) {
        self.database    = database;
        self.id          = id;
        self._name       = name;
        self._type       = type;
        self._searchable = searchable;
    }
    
    public class func optionalShared(id: String?, fromDatabase database: Database, withAccess access: SQLRead) -> Tag? {
        if let nnid = id {
            do {
                return try Tag.shared(nnid, fromDatabase: database, withAccess: access);
            }
            catch {
            }
        }
        
        return nil;
    }

    public class func shared(statement: SQLStatement, fromDatabase database: Database, withAccess access: SQLRead) -> Tag {
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
    
    public class func shared(id: String, fromDatabase database: Database, withAccess access: SQLRead) throws -> Tag {
        return try tagCache.get(id) {
            let statement = try access.prepare("SELECT name, type, searchable from dad_tag WHERE dad_tag_id = ?")
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

    internal class func create(id: String, name: String, type: String, searchable: Bool, withAccess access: SQLWrite) throws {
        let statement = try access.prepare("INSERT INTO dad_tag VALUES(?,?,?,?);")
        try statement.bind(id,         atIndex: 1);
        try statement.bind(name,       atIndex: 2);
        try statement.bind(type,       atIndex: 3);
        try statement.bind(searchable, atIndex: 2);
        try statement.step();
    }

    public var description: String {
        get {
            return name;
        }
    }

    public var isSpecial: Bool {
        get {
            return _type == TagType.Special.rawValue;
        }
    }
}

public func == (t1: Tag, t2: Tag) -> Bool {
    return t1.id == t2.id;
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

    public func addTag(name: String, type: TagType, withAccess access: SQLWrite) throws -> Tag {
        let s = try access.prepare("SELECT dad_tag_id FROM dad_tag WHERE name = ? AND type = ?")
        try s.bind(name, atIndex: 1);
        try s.bind(type.rawValue, atIndex: 2);
        
        if try s.step() {
            return Tag.shared(s, fromDatabase: self, withAccess: access);
        }

        var newID = (type.rawValue + "." + name).sha256();
        
        do {
            let s = try access.prepare("INSERT INTO dad_tag VALUES (?, ?, ?, 1);");
            try s.bind(newID, atIndex: 1);
            try s.bind(name, atIndex: 2);
            try s.bind(type.rawValue, atIndex: 3);
            try s.step();
        }
        catch SQLError.Constraint {
            newID = Database.createNewID();

            let s = try access.prepare("INSERT INTO dad_tag VALUES (?, ?, ?, 1);");
            try s.bind(newID, atIndex: 1);
            try s.bind(name, atIndex: 2);
            try s.bind(type.rawValue, atIndex: 3);
            try s.step();
        }

        let newTag = try Tag.shared(newID, fromDatabase: self, withAccess: access);

        dispatch_async_main {
            for delegate in self.delegates {
                delegate.tagAdded(newTag);
            }
        }
        
        return newTag;
    }

    public func findTags(type type: TagType, withAccess access: SQLRead) -> [Tag] {
        return findTags(type: type.rawValue, withAccess: access);
    }
    
    public func findTags(type type: String, withAccess access: SQLRead) -> [Tag] {
        do {
            let s = try access.prepare("SELECT * FROM dad_tag WHERE type = ? ORDER BY name COLLATE NOCASE")
            try s.bind(type, atIndex: 1);
            
            var tags = [Tag]();
            while try s.step() {
                tags.append(Tag.shared(s, fromDatabase: self, withAccess: access));
            }
            
            return tags;
        }
        catch {
            return [];
        }
    }
    
    public func findTags(title title: String, withAccess access: SQLRead) -> [Tag] {
        do {
            let s = try access.prepare("SELECT * FROM dad_tag WHERE name LIKE ?")
            try s.bind(title.asLikeClause, atIndex: 1);
                
            var tags = [Tag]();
            while try s.step() {
                tags.append(Tag.shared(s, fromDatabase: self, withAccess: access));
            }
                
            return tags;
        }
        catch {
            return [];
        }
    }

    public func findTag(title title: String, withAccess access: SQLRead) -> Tag? {
        do {
            let s = try access.prepare("SELECT * FROM dad_tag WHERE name = ? COLLATE NOCASE")
            try s.bind(title, atIndex: 1);

            if try s.step() {
                return Tag.shared(s, fromDatabase: self, withAccess: access);
            }
        }
        catch {
        }

        return nil;
    }

    public func tags(access: SQLRead) -> [Tag] {
        do {
            let s = try access.prepare("SELECT * FROM dad_tag WHERE searchable = 1")

            var tags = [Tag]();
            while try s.step() {
                tags.append(Tag.shared(s, fromDatabase: self, withAccess: access));
            }
                
            return tags;
        }
        catch {
            return [];
        }
    }

    public func normalizeTagTokens(sources: [AnyObject], withAccess access: SQLWrite) -> [AnyObject] {
        var output: [AnyObject] = [];

        output.reserveCapacity(sources.count);

        for source in sources {
            if let tag = source as? Tag {
                output.append(tag);
            }
            else if let tagInstance = source as? TagInstance {
                output.append(tagInstance);
            }
            else if let str = source as? String {
                if let tag = findTag(title: str, withAccess: access) {
                    output.append(tag);
                }
                else {
                    do {
                        output.append(try self.addTag(str, type: TagType.Unclassified, withAccess: access));
                    }
                    catch {
                    }
                }
            }
        }

        return output;
    }

    internal func createTagTable(access: SQLWrite) throws {
        let sql = "CREATE TABLE dad_tag(\n" +
            "  dad_tag_id            VARCHAR(64)  PRIMARY KEY,\n" +
            "  name                  VARCHAR(256) NOT NULL,\n" +
            "  type                  VARCHAR(64)  NOT NULL,\n" +
            "  searchable            INTEGER      DEFAULT 1\n" +
            ");";

        try access.exec(sql);
        try access.exec("INSERT INTO dad_tag VALUES ('\(StandardTagID.File.rawValue)', 'FILE', '\(TagType.Special.rawValue)', 0);");
        try access.exec("INSERT INTO dad_tag VALUES ('\(StandardTagID.Scene.rawValue)', 'SCENE', '\(TagType.Special.rawValue)', 0);");
        try access.exec("INSERT INTO dad_tag VALUES ('\(StandardTagID.Preview.rawValue)', 'PREVIEW', '\(TagType.Special.rawValue)', 0);");
        try access.exec("INSERT INTO dad_tag VALUES ('\(StandardTagID.DropBox.rawValue)', 'DROPBOX', '\(TagType.Special.rawValue)', 0);");
    }
}
