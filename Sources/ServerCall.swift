//
//  ServerCall.swift
//  Nix
//
//  Created by Bazyli Zygan on 04.09.2017.
//  Copyright © 2017 Nova Project. All rights reserved.
//

import Foundation

open class ServerCall {

    public enum Status: String {
        case idle = "idle"
        case running = "running"
        case finished = "finished"
    }
    
    public enum CallType: String {
        case data = "data"
        case download = "download"
        case upload = "upload"
    }
        
    open var userAgent: String {
        get {
            return "Nix/1.0"
        }
    }
    
    open var baseURLString: String {
        get {
            return Bundle.main.infoDictionary!["NixServerURL"] as? String ?? "localhost"
        }
    }
    
    open var type: CallType {
        get {
            return .data
        }
    }
    
    open var path: String {
        get {
            return ""
        }
    }
    
    open var method: HTTPMethod {
        get {
            return .get
        }
    }
    
    open var headers: [String: String]? {
        get {
            return nil
        }
    }
    
    open var parameters: [String: Any]? {
        get {
            return nil
        }
    }
    
    open var parameterEncoding: ParameterEncoding {
        get {
            return URLEncoding.default
        }
    }
    
    open var status: Status = .idle
    
    public var expectedDataSize: Int64 = 0
    public var data: Data? = nil
    public var responseObject: Any? = nil
    public var userData: Any? = nil
    public var response: URLResponse? = nil
    
    public var successBlock: ((Any?) -> Void)? = nil
    public var failureBlock: ((Error) -> Void)? = nil
    public var finalBlock: ((Bool) -> Void)? = nil
    public var progressBlock: ((Int64, Int64) -> Void)? = nil
    
    public init(executeNow: Bool = true) {
        if executeNow {
            DispatchQueue.main.async {
                do {
                    try self.execute()
                } catch let error {
                    self.failureBlock?(error)
                    self.finalBlock?(false)
                }
            }
        }
    }
        
    open func execute() throws {
        if status != .idle {
            throw NixError.alreadyRunning
        }
        
        try NixManager.shared.execute(self)
    }
    
    open func onResponseReceived(_ response: URLResponse) -> Bool {
        return true
    }
    
    open func onDataSent(bytesSent: Int64, totalBytesToBeSent: Int64) {
        
    }

    open func onDataReceived(bytesReceived: Int64, totalBytesToBeReceived: Int64) {
        
    }
    
    open func onFinish(error: Error?) -> ServerCall? {
        
        // Try to parse content based on type received in the header
        
        return nil
    }
    
    @discardableResult open func progress(_ progress: @escaping (Int64, Int64) -> Void) -> ServerCall {
        
        progressBlock = progress
        return self
    }

    
    @discardableResult open func success(_ success: @escaping (Any?) -> Void) -> ServerCall {
        
        successBlock = success
        return self
    }

    @discardableResult open func failure(_ failure: @escaping (Error) -> Void) -> ServerCall {
        
        failureBlock = failure
        return self
    }
    
    @discardableResult open func finally(_ finally: @escaping (Bool) -> Void) -> ServerCall {
        
        finalBlock = finally
        return self
    }
}
