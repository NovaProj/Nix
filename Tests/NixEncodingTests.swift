//
//  NixEncodingTests.swift
//  Nix iOS Test
//
//  Created by Bazyli Zygan on 09.01.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import XCTest
@testable import Nix

class NixEncodingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testSimpleXMLResultCall() {
        let xmlExpectation = self.expectation(description: "Call to generic GET request should finish with solid data")
        
        QuickCall(URL(string: "https://httpbin.org/xml")!).success { (data) in
            //Succeeded
            if data is XMLParser {
                xmlExpectation.fulfill()
            }
        
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
