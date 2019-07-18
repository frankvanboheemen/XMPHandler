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
    
//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }

    func testTestFileDirFound () {
        XCTAssert(FileManager.default.fileExists(atPath: testFileDir.path))
    }
    
    func testParseXMP() {
        let validXMPFileURL = testFileDir.appendingPathComponent("valid-xmp.xmp")
        XCTAssert(FileManager.default.fileExists(atPath:validXMPFileURL.path))
        
        do {
            let result = try xmpHandler.parseXMP(from: validXMPFileURL)
            XCTAssert(result.attributes != nil)
            XCTAssert(result.dcObjects != nil)
        } catch let error {
            print(error)
        }

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
        
    }

    func testSaveXMPInNewFile() {
        
    }
    
    func testUpdateXMPInFile() {
        
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
