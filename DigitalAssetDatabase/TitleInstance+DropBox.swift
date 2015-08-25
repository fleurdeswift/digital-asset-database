//
//  TitleInstance+DropBox.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import SQL
import ExtraDataStructures

public extension TitleInstance {
    public func removeFromDropbox(access: SQLWrite) throws {
        try access.exec("DELETE FROM dad_tag_instance WHERE dad_tag_id = '\(StandardTagID.DropBox.rawValue)' AND dad_title_instance_id = '\(self.id)'")
        database.fireTitleInstanceTagsChanged(self, tags: []);
    }
}

public extension Database {
    public func dropBox(maxResults: Int, before: NSTimeInterval, withAccess access: SQLRead) -> [TitleInstance] {
        do {
            let dropBoxSQL =
                "SELECT dad_title_instance_id " +
                "FROM   dad_tag_instance " +
                "WHERE  dad_title_instance_id IS NOT NULL AND " +
                "       dad_tag_id = '\(StandardTagID.DropBox.rawValue)'"

            let sql = "SELECT   * " +
                      "FROM     dad_title_instance " +
                      "WHERE    dad_title_instance_id IN (\(dropBoxSQL)) AND " +
                      "         date_added < ? " +
                      "ORDER BY date_added DESC " +
                      "LIMIT  \(maxResults)";

            let statement = try access.prepare(sql);
            var results   = [TitleInstance]();

            try statement.bind(before, atIndex: 1)

            while try statement.step() {
                do {
                    results.append(try TitleInstance.shared(statement, fromDatabase: self, withAccess: access));
                }
                catch {
                }
            }

            return results;
        }
        catch {
            return [];
        }
    }

    public func dropBox(maxResults: Int, after: NSTimeInterval, withAccess access: SQLRead) -> [TitleInstance] {
        do {
            let dropBoxSQL =
                "SELECT dad_title_instance_id " +
                "FROM   dad_tag_instance " +
                "WHERE  dad_title_instance_id IS NOT NULL AND " +
                "       dad_tag_id = '\(StandardTagID.DropBox.rawValue)'"

            let sql = "SELECT   * " +
                      "FROM     dad_title_instance " +
                      "WHERE    dad_title_instance_id IN (\(dropBoxSQL)) AND " +
                      "         date_added > ? " +
                      "ORDER BY date_added " +
                      "LIMIT  \(maxResults)";

            let statement = try access.prepare(sql);
            var results   = [TitleInstance]();

            try statement.bind(after, atIndex: 1)

            while try statement.step() {
                do {
                    results.append(try TitleInstance.shared(statement, fromDatabase: self, withAccess: access));
                }
                catch {
                }
            }

            return results;
        }
        catch {
            return [];
        }
    }

    public func dropBox(maxResults: Int, withAccess access: SQLRead) -> [TitleInstance] {
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

            return results;
        }
        catch {
            return [];
        }
    }

    public func dropBox(maxResults: Int, block: ([TitleInstance]) -> Void) -> Void {
        handle.readAsync { (access: SQLRead) in block(self.dropBox(maxResults, withAccess: access)) }
    }
}
