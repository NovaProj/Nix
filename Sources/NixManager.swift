//
//  NixManager.swift
//  Nix
//
//  Created by Bazyli Zygan on 04.09.2017.
//  Copyright © 2017 Nova Project. All rights reserved.
//

import Foundation

open class NixManager: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
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
                break
            case .download:
                task = defaultSession.downloadTask(with: request)
                break
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
    
    
    // MARK: - Data task delegates
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        tasks[dataTask]?.response = response
        if tasks[dataTask]?.onResponseReceived(response) ?? false {
            if let httpResponse = response as? HTTPURLResponse {
                let expectedSize = Int64((httpResponse.allHeaderFields["Content-Length"] as? String) ?? "0") ?? 0
                if expectedSize > 0 {
                    tasks[dataTask]?.expectedDataSize = expectedSize
                }
            }
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        let call = tasks[dataTask]
        if call?.stream == nil {
            call?.stream = OutputStream(toMemory: ())
            call?.stream?.open()
        }
        
        call?.stream?.write(data: data)
        call?.receivedDataSize += Int64(data.count)
        call?.onDataReceived(bytesReceived: call!.receivedDataSize, totalBytesToBeReceived: call!.expectedDataSize)
        call?.progressBlock?(call!.receivedDataSize, call!.expectedDataSize)
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
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let call = tasks[task]
        
        call?.onDataSent(bytesSent: totalBytesSent, totalBytesToBeSent: totalBytesExpectedToSend)
        call?.progressBlock?(totalBytesSent, totalBytesExpectedToSend)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Unload data from savers
        let call = tasks.removeValue(forKey: task)
        
        // First - let's try to decode response that we have
        call?.stream?.close()
        let callData = call?.stream?.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
        
        if callData != nil {
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
                    call?.responseObject = try decoder?.decode(callData!)
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
                if call?.type == .data {
                    call?.successBlock?(call?.responseObject)
                }
            } else {
                call?.failureBlock?(realError!)
            }
            call?.finalBlock?(realError == nil)
        }
    }
    
    // MARK: - Download task delegates
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let call = tasks.removeValue(forKey: downloadTask)
        
        call?.successBlock?(location)
        call?.finalBlock?(true)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        let call = tasks[downloadTask]
        call?.receivedDataSize = fileOffset
        call?.expectedDataSize = expectedTotalBytes
        
        call?.onDataReceived(bytesReceived: fileOffset, totalBytesToBeReceived: expectedTotalBytes)
        call?.progressBlock?(fileOffset, expectedTotalBytes)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let call = tasks[downloadTask]
        call?.receivedDataSize = totalBytesWritten
        call?.expectedDataSize = totalBytesExpectedToWrite
        
        call?.onDataReceived(bytesReceived: totalBytesWritten, totalBytesToBeReceived: totalBytesExpectedToWrite)
        call?.progressBlock?(totalBytesWritten, totalBytesExpectedToWrite)
    }
}
