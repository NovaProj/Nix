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
    

    func testSimpleXMLResultCall() {
        let xmlExpectation = self.expectation(description: "Call to generic GET request should finish with solid data")
        
        QuickCall(URL(string: "http://httpbin.org/xml")!).success { (data) in
            //Succeeded
            if data is XMLParser {
                xmlExpectation.fulfill()
            }
        
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
