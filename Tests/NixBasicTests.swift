//
//  NixBasicTests.swift
//  Nix Tests
//
//  Created by Bazyli Zygan on 04.09.2017.
//  Copyright © 2017 Nova Project. All rights reserved.
//

import XCTest
@testable import Nix

class NixBasicTests: XCTestCase {
    
    func testSimpleGETCall() {
        let httpExpectation = self.expectation(description: "Call to generic GET request should finish with solid data")
        let headerExpectation = self.expectation(description: "Call to generic GET request should contain fiven user agent")
        let parametersExpectation = self.expectation(description: "Call to generic GET request should parse parameters correctly")
        let finalExpectation = self.expectation(description: "All calls should finish with final block. Always.")
        
        QuickCall(URL(string: "http://httpbin.org/get")!, parameters: ["stringTest": "test", "numberTest": 2]).success { (data) in
                //Succeeded
            if data is [String: Any] {
                httpExpectation.fulfill()
                
                let responseDict = (data as! [String: Any])
                // Arguments
                let arguments = responseDict["args"] as? [String: Any] ?? [String: Any]()
                let headers = responseDict["headers"] as? [String: Any] ?? [String: Any]()
                
                if (headers["User-Agent"] as? String) == "Nix/1.0" {
                    headerExpectation.fulfill()
                }
                if (arguments["stringTest"] as? String) == "test" &&
                    (arguments["numberTest"] as? String) == "2" {
                    parametersExpectation.fulfill()
                }
            }
            }.finally { (succeeded) in
                if succeeded {
                    finalExpectation.fulfill()
                }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimplePOSTCall() {
        let httpExpectation = self.expectation(description: "Call to generic POST request should finish with solid data")
        let headerExpectation = self.expectation(description: "Call to generic POST request should contain fiven user agent")
        let parametersExpectation = self.expectation(description: "Call to generic POST request should parse parameters correctly")
        let finalExpectation = self.expectation(description: "All calls should finish with final block. Always.")
        
        QuickCall(URL(string: "http://httpbin.org/post")!, method: .post, parameters: ["stringTest": "test", "numberTest": 2]).success { (data) in
            //Succeeded
            httpExpectation.fulfill()
            if data is [String: Any] {

                
                let responseDict = (data as! [String: Any])
                // Arguments
                let arguments = responseDict["form"] as? [String: Any] ?? [String: Any]()
                let headers = responseDict["headers"] as? [String: Any] ?? [String: Any]()

                if (headers["User-Agent"] as? String) == "Nix/1.0" {
                    headerExpectation.fulfill()
                }
                if (arguments["stringTest"] as? String) == "test" &&
                    (arguments["numberTest"] as? String) == "2" {
                    parametersExpectation.fulfill()
                }
            }
            }.finally { (succeeded) in
                if succeeded {
                    finalExpectation.fulfill()
                }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimplePUTCall() {
        let httpExpectation = self.expectation(description: "Call to generic PUT request should finish with solid data")
        let headerExpectation = self.expectation(description: "Call to generic PUT request should contain fiven user agent")
        let parametersExpectation = self.expectation(description: "Call to generic PUT request should parse parameters correctly")
        let finalExpectation = self.expectation(description: "All calls should finish with final block. Always.")
        
        QuickCall(URL(string: "http://httpbin.org/put")!, method: .put, parameters: ["stringTest": "test", "numberTest": 2]).success { (data) in
            //Succeeded
            if data is [String: Any] {
                httpExpectation.fulfill()
                
                let responseDict = (data as! [String: Any])
                // Arguments
                let arguments = responseDict["form"] as? [String: Any] ?? [String: Any]()
                let headers = responseDict["headers"] as? [String: Any] ?? [String: Any]()
                
                if (headers["User-Agent"] as? String) == "Nix/1.0" {
                    headerExpectation.fulfill()
                }
                if (arguments["stringTest"] as? String) == "test" &&
                    (arguments["numberTest"] as? String) == "2" {
                    parametersExpectation.fulfill()
                }
            }
            }.finally { (succeeded) in
                if succeeded {
                    finalExpectation.fulfill()
                }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimplePATCHCall() {
        let httpExpectation = self.expectation(description: "Call to generic PATCH request should finish with solid data")
        let headerExpectation = self.expectation(description: "Call to generic PATCH request should contain fiven user agent")
        let parametersExpectation = self.expectation(description: "Call to generic PATCH request should parse parameters correctly")
        let finalExpectation = self.expectation(description: "All calls should finish with final block. Always.")
        
        QuickCall(URL(string: "http://httpbin.org/patch")!, method: .patch, parameters: ["stringTest": "test", "numberTest": 2]).success { (data) in
            //Succeeded
            if data is [String: Any] {
                httpExpectation.fulfill()
                
                let responseDict = (data as! [String: Any])
                // Arguments
                let arguments = responseDict["form"] as? [String: Any] ?? [String: Any]()
                let headers = responseDict["headers"] as? [String: Any] ?? [String: Any]()
                
                if (headers["User-Agent"] as? String) == "Nix/1.0" {
                    headerExpectation.fulfill()
                }
                if (arguments["stringTest"] as? String) == "test" &&
                    (arguments["numberTest"] as? String) == "2" {
                    parametersExpectation.fulfill()
                }
            }
            }.finally { (succeeded) in
                if succeeded {
                    finalExpectation.fulfill()
                }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimpleDELETECall() {
        let httpExpectation = self.expectation(description: "Call to generic DELETE request should finish with solid data")
        let headerExpectation = self.expectation(description: "Call to generic DELETE request should contain fiven user agent")
        let parametersExpectation = self.expectation(description: "Call to generic DELETE request should parse parameters correctly")
        let finalExpectation = self.expectation(description: "All calls should finish with final block. Always.")
        
        QuickCall(URL(string: "http://httpbin.org/delete")!, method: .delete, parameters: ["stringTest": "test", "numberTest": 2]).success { (data) in
            //Succeeded
            if data is [String: Any] {
                httpExpectation.fulfill()
                
                let responseDict = (data as! [String: Any])
                // Arguments
                let arguments = responseDict["form"] as? [String: Any] ?? [String: Any]()
                let headers = responseDict["headers"] as? [String: Any] ?? [String: Any]()
                
                if (headers["User-Agent"] as? String) == "Nix/1.0" {
                    headerExpectation.fulfill()
                }
                if (arguments["stringTest"] as? String) == "test" &&
                    (arguments["numberTest"] as? String) == "2" {
                    parametersExpectation.fulfill()
                }
            }
            }.finally { (succeeded) in
                if succeeded {
                    finalExpectation.fulfill()
                }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testSimpleError() {
        let httpErrorExpectation = self.expectation(description: "Call should return 404 error")
        let finalExpectation = self.expectation(description: "All calls should finish with final block. Always.")
        
        QuickCall(URL(string: "http://httpbin.org/status/404")!).failure { (error) in
            
            if error is NixError {
                switch error as? NixError ?? .unknown {
                    case .httpError(let code):
                        if code == 404 {
                            httpErrorExpectation.fulfill()
                        }
                        break
                    default:
                        break
                }
            }

            }.finally { (succeeded) in
                if !succeeded {
                    finalExpectation.fulfill()
                }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
