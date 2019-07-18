//
//  XMPHandlerTests.swift
//  XMPHandlerTests
//
//  Created by Frank van Boheemen on 18/07/2019.
//  Copyright © 2019 Frank van Boheemen. All rights reserved.
//

import XCTest
@testable import XMPHandler

class XMPHandlerTests: XCTestCase {
    
    private var testFileDir : URL {
        get {
            return URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("testFiles")
        }
    }
    private let xmpHandler = XMPHandler()

    func testTestFileDirFound () {
        XCTAssert(FileManager.default.fileExists(atPath: testFileDir.path))
    }
    
    func testParseXMP() {
        let validXMPFileURL = testFileDir.appendingPathComponent("valid.xmp")
        XCTAssert(FileManager.default.fileExists(atPath:validXMPFileURL.path))
        
        XCTAssertNoThrow(try? xmpHandler.parseXMP(from: validXMPFileURL))
    }
    
    func testThrowErrorWhenFileIsNotFound() {
        let brokenURL = testFileDir.appendingPathComponent("brokenURL.xmp")
        XCTAssert(!FileManager.default.fileExists(atPath:brokenURL.path))
        
        do {
            let _ = try xmpHandler.parseXMP(from: brokenURL)
        } catch let error {
            print(error)
            XCTAssert(true)
        }
    }
    
    func testThrowErrorWhenParsingInvalidXMP() {
        let invalidXMPURL = testFileDir.appendingPathComponent("html-in-xmp-file.xmp")
        XCTAssert(FileManager.default.fileExists(atPath:invalidXMPURL.path))
        
        do {
            let _ = try xmpHandler.parseXMP(from: invalidXMPURL)
        } catch let error {
            print(error)
            XCTAssert(true)
        }
        
    }

    func testSaveXMPInNewFile() {
        //This test will fail when the app is in Sandbox-mode
        
        let newXMPURL = testFileDir.appendingPathComponent("new.xmp")
        
        if FileManager.default.fileExists(atPath: newXMPURL.path) {
            try? FileManager.default.removeItem(at: newXMPURL)
        }
        
        XCTAssert(!FileManager.default.fileExists(atPath: newXMPURL.path))
        
        let attributes = ["xmp:Rating" : "2"]
        
        xmpHandler.saveXMP(attributes: attributes, objects: [:], to: newXMPURL)
        
        XCTAssert(FileManager.default.fileExists(atPath: newXMPURL.path))
        
    }
    
    func testUpdateXMPInFile() {
        //This test will fail when the app is in Sandbox-mode
        let xmpURL = testFileDir.appendingPathComponent("to-update.xmp")

        let newAttributes = ["xmp:Rating" : "5"]
        
        guard let result = try? xmpHandler.parseXMP(from: xmpURL),
            let rating = result.attributes?["xmp:Rating"] else {
            XCTFail()
            return
        }
        
        XCTAssert(rating != newAttributes["xmp:Rating"])
        
        xmpHandler.saveXMP(attributes: newAttributes, objects: [:], to: xmpURL)
        
        guard let newResult = try? xmpHandler.parseXMP(from: xmpURL),
            let newRating = newResult.attributes?["xmp:Rating"] else {
                XCTFail()
                return
        }
        
        XCTAssert(newRating == newAttributes["xmp:Rating"])

        //Reset file
        let oldAttributes = ["xmp:Rating" : rating]
        xmpHandler.saveXMP(attributes: oldAttributes, objects: [:], to: xmpURL)
    }
    
    /*TODO: Test performance with large XMP-files (if that's even a thing)
        func testPerformance() {
            self.measure {
                // Put the code you want to measure the time of here.
            }
        }
    */
}
