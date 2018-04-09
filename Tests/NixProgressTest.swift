//
//  NixProgressTest.swift
//  Nix iOS Test
//
//  Created by Bazyli Zygan on 09.04.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import XCTest
@testable import Nix

class NixProgressTest: XCTestCase {
    
    func testDownloadProgress() {
        let expectProgressUpdates = expectation(description: "Call expected to deliver at least one update on finish download")
        var expectationFilled = false
        QuickCall(URL(string: "http://httpbin.org/bytes/1024")!).progress { (got, total) in
            print("Got \(got) of total \(total)")
            if got == 1024 && total == 1024 && !expectationFilled {
                expectationFilled = true
                expectProgressUpdates.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}
