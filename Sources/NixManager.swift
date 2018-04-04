//
//  NixManager.swift
//  Nix
//
//  Created by Bazyli Zygan on 04.09.2017.
//  Copyright © 2017 Nova Project. All rights reserved.
//

import Foundation

open class NixManager: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    
    private var defaultSession: URLSession!
    private var tasks = [URLSessionTask: ServerCall]()
    private var decoders = [String: ResponseDecoding]()
    
    open static let shared: NixManager = {
        return NixManager()
    }()
    
    open var trustDelegate: NixTrustDelegate? = nil
    
    public override init() {
        super.init()
        defaultSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        // Register known decoders
        register(decoder: JSONDecoding())
        register(decoder: XMLDecoding())
    }
    
    public func execute(_ call: ServerCall) throws {
        
        let request = try buildRequest(call)
        var task: URLSessionTask? = nil
        
        switch call.type {
        case .data:
                task = defaultSession.dataTask(with: request)
            
            default:
                throw NixError.notImplemented
        }
        
        if task == nil {
            throw NixError.unknown
        }
        
        tasks[task!] = call
        task?.resume()
    }
    
    public func register(decoder: ResponseDecoding) {
        decoders[decoder.contentType.lowercased()] = decoder
    }
    
    private func buildRequest(_ call: ServerCall) throws -> URLRequest {
                
        return try call.parameterEncoding.encode(call)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        tasks[dataTask]?.response = response
        if tasks[dataTask]?.onResponseReceived(response) ?? false {
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if tasks[dataTask]?.data != nil {
           tasks[dataTask]?.data?.append(data)
        } else {
            tasks[dataTask]?.data = data
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host
            
            if
                (trustDelegate?.nixManager(self, shouldTrustHost: host) ?? false),
                let serverTrust = challenge.protectionSpace.serverTrust
            {
                disposition = .useCredential
                credential = URLCredential(trust: serverTrust)
            } else {
                disposition = .cancelAuthenticationChallenge
            }
        }
        
        completionHandler(disposition, credential)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Unload data from savers
        let call = tasks.removeValue(forKey: task)
        
        // First - let's try to decode response that we have
        if call?.data != nil {
            let headers = (call?.response as? HTTPURLResponse)?.allHeaderFields
            let cT = headers?["Content-Type"] ?? headers?["Content-type"] ?? headers?["content-type"]
            
            if cT is String {
                // It might be, that cT has additional parameters attached - we ditch them for now
                var contentType = cT as! String
                if let semiRange = contentType.range(of: ";") {
                    contentType.removeSubrange(semiRange.lowerBound..<contentType.endIndex)
                }
                let decoder = decoders[contentType.lowercased()]
                
                do {
                    call?.responseObject = try decoder?.decode(call!.data!)
                } catch {
                    call?.failureBlock?(NixError.responseParseError)
                    call?.finalBlock?(false)
                    return
                }
            }
        }
        
        // There's a chance that lack of error doesn't mean there isn't one
        let httpCode = (call?.response as? HTTPURLResponse)?.statusCode ?? 0
        let realError = error ?? ((httpCode > 299) ? NixError.httpError(httpCode) : nil)
        
        // Second - we need to check if that's over or not
        let continuityCall = call?.onFinish(error: realError)
        if continuityCall != nil {
            continuityCall?.finalBlock = call?.finalBlock
            continuityCall?.successBlock = call?.successBlock
            continuityCall?.failureBlock = call?.failureBlock
            continuityCall?.userData = call?.userData
            
            DispatchQueue.main.async {
                do {
                    try self.execute(continuityCall!)
                } catch {}
            }
        } else {
            if realError == nil {
                call?.successBlock?(call?.responseObject)
            } else {
                call?.failureBlock?(realError!)
            }
            call?.finalBlock?(realError == nil)
        }
    }
}
