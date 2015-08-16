//
//  DigitalAssetDatabaseTests.swift
//  DigitalAssetDatabaseTests
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import XCTest
import SQL
@testable import DigitalAssetDatabase

class DigitalAssetDatabaseTests: XCTestCase {
    func testCreateAndFindNewTitles() {
        do {
            let database = try Database(path: ":memory:");
            let title1   = try Title(createWithName: "The Matrix", inDatabase: database);
            let title2   = try Title(createWithName: "Star Wars",  inDatabase: database);
            
            XCTAssertEqual(title1.id.characters.count, 64);
            XCTAssertEqual(title1.name, "The Matrix");
            
            var expect = self.expectationWithDescription("Search");
            
            database.findTitles("MATR") {
                (titles: [Title]) in
                    XCTAssertEqual(titles.count, 1);
                    XCTAssertEqual(titles[0].id,   title1.id);
                    XCTAssertEqual(titles[0].name, title1.name);
                    expect.fulfill();
            }
            
            self.waitForExpectationsWithTimeout(2, handler: nil);

            expect = self.expectationWithDescription("Search");
            
            database.findTitles("star") {
                (titles: [Title]) in
                    XCTAssertEqual(titles.count, 1);
                    XCTAssertEqual(titles[0].id,   title2.id);
                    XCTAssertEqual(titles[0].name, title2.name);
                    expect.fulfill();
            }
            
            self.waitForExpectationsWithTimeout(2, handler: nil);
        }
        catch {
            XCTFail();
        }
    }

    func testCreateTitleInstanceWithFiles() {
        do {
            let database = try Database(path: ":memory:");
            let title    = try Title(createWithName: "The Matrix", inDatabase: database);
            let files = [
                TitleInstanceFile(fileName: "a.mp4", duration: 60),
                TitleInstanceFile(fileName: "b.mp4", duration: 70),
                TitleInstanceFile(fileName: "c.mp4", duration: 80)
            ];
            
            let instance  = try TitleInstance(createWithFiles: files, title: title, inDatabase: database);
            
            XCTAssertEqual(instance.id.characters.count, 64);
            
            let instances = try title.instances()

            XCTAssertEqual(instances.count, 1);
            XCTAssert(instances[0] === instance);
            
            let tagFiles = try instances[0].files();
            
            XCTAssertEqual(tagFiles.count, 3);
            XCTAssertEqualWithAccuracy(tagFiles[0].start, 00, accuracy: 0.1);
            XCTAssertEqualWithAccuracy(tagFiles[1].start, 60, accuracy: 0.1);
            XCTAssertEqualWithAccuracy(tagFiles[2].start, 130, accuracy: 0.1);
        }
        catch {
            XCTFail();
        }
    }

    func testRenameTag() {
        do {
            let database = try Database(path: ":memory:");
            let tag      = try Tag.shared(StandardTagID.File.rawValue, fromDatabase: database);
            
            XCTAssertEqual(tag.id,         StandardTagID.File.rawValue);
            XCTAssertEqual(tag.name,       "FILE");
            XCTAssertEqual(tag.type,       TagType.Special.rawValue);
            XCTAssertEqual(tag.searchable, false);
            
            tag.name = "MIAW";
            tag.type = "WOOF";
            tag.searchable = true;
            
            let expect = self.expectationWithDescription("Search");
            
            database.findTags(title: "MIAW") { (tags: [Tag]) in
                XCTAssertEqual(tags.count, 1)
                XCTAssertEqual(tags[0].id, StandardTagID.File.rawValue)
                expect.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(2, handler: nil);
        }
        catch {
            XCTFail();
        }
    }

    func testAddTag() {
        do {
            let database = try Database(path: ":memory:");
            let bedroom1 = try database.addTag("Bedroom", type: TagType.Set);
            let bedroom2 = try database.addTag("Bedroom", type: TagType.Set);
            
            XCTAssert(bedroom1 === bedroom2);
            bedroom1.name = "Old Bedroom";
            
            let bedroom3 = try database.addTag("Bedroom", type: TagType.Set);
            XCTAssert(bedroom1 !== bedroom3);
        }
        catch {
            XCTFail();
        }
    }
    
    func testCreateID() {
        XCTAssertEqual(Database.createNewID().characters.count, 64);
    }
}
