//
//  NixSequencedCallsTest.swift
//  Nix iOS Test
//
//  Created by Bazyli Zygan on 30.03.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import XCTest
@testable import Nix

class TestCall: ServerCall {
    override var baseURLString: String {
        get {
            return "https://httpbin.org"
        }
    }
}

class NestedCall: TestCall {
    
    override var path: String {
        get {
            return "anything"
        }
    }
}

class InitialCall: TestCall {
    
    override var path: String {
        get {
            return "get"
        }
    }
    
    override func onFinish(error: Error?) -> ServerCall? {
        if (error == nil) {
            userData = "testData"
            return NestedCall()
        }
        
        return nil
    }
}

class NixSequencedCallsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNestedCall() {
        let successExpectation = self.expectation(description: "Call should finish with the success")
        let responseExpectation = self.expectation(description: "Call should finish after nested call has all results")
        let finishExpectation = self.expectation(description: "Call should always call onFinish")
        
        InitialCall().success { (data) in
            successExpectation.fulfill()
            if ((data as? [String: Any])?["url"] as? String)?.contains("/anything") ?? false {
                responseExpectation.fulfill()
            }
        }.finally { (success) in
                finishExpectation.fulfill()
        }
        
         waitForExpectations(timeout: 4, handler: nil)
    }
}
