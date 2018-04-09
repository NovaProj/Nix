//
//  NixMultipartTests.swift
//  Nix iOS Test
//
//  Created by Bazyli Zygan on 06.04.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import XCTest
@testable import Nix

class InvalidCallMethodCall: ServerCall {
    override var parameterEncoding: ParameterEncoding {
        return MultipartFormDataEncoding.default
    }
}

class BadParametersCall: InvalidCallMethodCall {
    override var method: HTTPMethod {
        return .post
    }
    
    override var parameters: [String : Any]? {
        return ["wrongParam": URL(string: "http://httpbin.org")!]
    }
}

class SimpleMultipartCall: BadParametersCall {
    
    override var baseURLString: String {
        return "http://httpbin.org"
    }
    
    override var path: String {
        return "/post"
    }
    
    override var parameters: [String : Any]? {
        return ["boolParam": true, "numberParam": 10, "stringParam": "someString"]
    }
}

var bundle: Bundle? = nil

class FileMultipartCall: SimpleMultipartCall {
    
    override var parameters: [String : Any]? {        
        return ["stringParam": "someString", "fileParam": bundle!.url(forResource: "test", withExtension: "html")!]
    }
}

class NixMultipartTests: XCTestCase {

    override func setUp() {
        bundle = Bundle(for: type(of: self))
    }
    func testFailingMultipartAtBadCallType() {
        let badMethodExpectation = expectation(description: "Creation of call with wrong method for multipart encoding should end up with an exception")
        let badParamExpectation = expectation(description: "Creation of call with wrong parameters for multipart encoding should end up with an exception")
        
        InvalidCallMethodCall().failure { (error) in
            switch error as? NixError ?? .unknown {
                case .invalidCallMethod:
                    badMethodExpectation.fulfill()
                    break
                default:
                    break
            }
        }
        
        BadParametersCall().failure { (error) in
            switch error as? NixError ?? .unknown {
                case .invalidParameters(let params):
                    if params["wrongParam"] is URL {
                        badParamExpectation.fulfill()
                    }
                    break
                default:
                    break
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)

    }
    
    func testBasicMultipartParameters() {
        
        let successExpectation = expectation(description: "Simple multipart call should finish with success")
        let paramsExpectation = expectation(description: "Simple multipart call should send all params programmed")
        
        SimpleMultipartCall().success { (data) in
            successExpectation.fulfill()
            
            let responseDict = (data as! [String: Any])
            // Arguments
            let arguments = responseDict["form"] as? [String: Any] ?? [String: Any]()
            if let boolParam = arguments["boolParam"] as? String,
               let stringParam = arguments["stringParam"] as? String,
               let numberParam = arguments["numberParam"] as? String {
                
                if boolParam == "true" && stringParam == "someString" && numberParam == "10" {
                    paramsExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFileMultipartParameters() {
        let successExpectation = expectation(description: "File multipart call should finish with success")
        let paramsExpectation = expectation(description: "File multipart call should send all params programmed")
        
        FileMultipartCall().success { (data) in
            successExpectation.fulfill()
            
            let responseDict = (data as! [String: Any])
            // Arguments
            let arguments = responseDict["form"] as? [String: Any] ?? [String: Any]()
            let files = responseDict["files"] as? [String: Any] ?? [String: Any]()
            if let stringParam = arguments["stringParam"] as? String,
               let _ = files["fileParam"] as? String{
                
                if stringParam == "someString" {
                    paramsExpectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
