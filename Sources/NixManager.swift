import Foundation

open class NixManager: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    private var defaultSession: URLSession!
    private var tasks = [URLSessionTask: ServerCall]()
    private var decoders = [String: ResponseDecoding]()
    
    open var dispatchQueue = DispatchQueue.main
    open var logger: NixLogger?
    
    public static let shared: NixManager = {
        return NixManager()
    }()
    
    open var trustDelegate: NixTrustDelegate? = nil
    open var trustedHosts: [String]?
    
    open var cache: NixCache?
    
    public override init() {
        super.init()
        defaultSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        // Set default cache control manager
        cache = L1L2Cache()
        
        // Register known decoders
        register(decoder: JSONDecoding())
        register(decoder: XMLDecoding())
    }
    
    public func execute(_ call: ServerCall) throws {
        guard call.isValid else {
            close(call: call, error: NixError.invalid, data: nil)
            return
        }
        
        let request = try buildRequest(call)
        var futureTask: URLSessionTask? = nil
        
        switch call.type {
            case .data:
                futureTask = defaultSession.dataTask(with: request)
                break
            case .download:
                futureTask = defaultSession.downloadTask(with: request)
                break
            
            default:
                throw NixError.notImplemented
        }
        
        guard let task = futureTask else {
            throw NixError.unknown
        }
        
        tasks[task] = call
        call.task = task
        call.request = request
        logger?.prepared(manager: self, call: call)
        if call.onCallPrepared() {
            task.resume()
        } else {
            tasks[task] = nil
            finished(call: call, withError: nil)            
        }
    }
    
    public func cancel(_ call: ServerCall) throws {
        if let task = call.task {
            task.cancel()
            tasks.removeValue(forKey: task)
            dispatchQueue.async { [weak self] in
                if let s = self {
                    s.logger?.finished(manager: s, call: call, withError: NixError.cancelled)
                }
                call.finalBlock?(false)
            }            
        }
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
        if let realLogger = logger, let call = tasks[dataTask] {
            dispatchQueue.async { [weak self] in
                if let s = self {
                    realLogger.receivedHeader(manager: s, forCall: call)
                }
            }
        }
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
        
        guard let call = tasks[dataTask] else {
            return
        }
        if call.stream == nil {
            call.stream = OutputStream(toMemory: ())
            call.stream?.open()
        }
        
        call.stream?.write(data: data)
        call.receivedDataSize += Int64(data.count)
        call.onDataReceived(bytesReceived: call.receivedDataSize, totalBytesToBeReceived: call.expectedDataSize)
        call.progressBlock?(call.receivedDataSize, call.expectedDataSize)
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
                (trustedHosts?.contains(host) ?? false || trustDelegate?.nixManager(self, shouldTrustHost: host) ?? false),
                let serverTrust = challenge.protectionSpace.serverTrust
            {
                disposition = .useCredential
                credential = URLCredential(trust: serverTrust)
            } else {
                disposition = .performDefaultHandling
            }
        }
        
        completionHandler(disposition, credential)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let call = tasks[task]
        
        call?.onDataSent(bytesSent: totalBytesSent, totalBytesToBeSent: totalBytesExpectedToSend)
        dispatchQueue.async {
            call?.progressBlock?(totalBytesSent, totalBytesExpectedToSend)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Unload data from savers
        guard let call = tasks.removeValue(forKey: task) else {
            return
        }
        
        finished(call: call, withError: error)
    }
    
    // MARK: - Download task delegates
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let call = tasks.removeValue(forKey: downloadTask)
        
        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("tmp")
        do {try FileManager.default.moveItem(at: location, to: tempUrl)
            dispatchQueue.async {
                call?.successBlock?(tempUrl)
                call?.finalBlock?(true)
                do { try FileManager.default.removeItem(at: tempUrl) } catch {}
            }
        } catch let error {
            call?.failureBlock?(error)
            call?.finalBlock?(false)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        let call = tasks[downloadTask]
        call?.receivedDataSize = fileOffset
        call?.expectedDataSize = expectedTotalBytes
        
        dispatchQueue.async {
            call?.onDataReceived(bytesReceived: fileOffset, totalBytesToBeReceived: expectedTotalBytes)
            call?.progressBlock?(fileOffset, expectedTotalBytes)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let call = tasks[downloadTask]
        call?.receivedDataSize = totalBytesWritten
        call?.expectedDataSize = totalBytesExpectedToWrite
        
        dispatchQueue.async {
            call?.onDataReceived(bytesReceived: totalBytesWritten, totalBytesToBeReceived: totalBytesExpectedToWrite)
            call?.progressBlock?(totalBytesWritten, totalBytesExpectedToWrite)
        }
    }
    
    private func finished(call: ServerCall, withError error: Error?) {
        // First - let's try to decode response that we have
        call.stream?.close()
        let callData = call.stream?.property(forKey: .dataWrittenToMemoryStreamKey) as? Data ?? call.data
        
        if callData != nil {
            if var contentType = call.contentType {
                // It might be, that cT has additional parameters attached - we ditch them for now
                if let semiRange = contentType.range(of: ";") {
                    contentType.removeSubrange(semiRange.lowerBound..<contentType.endIndex)
                }
                let decoder = call.responseDecoding ?? decoders[contentType.lowercased()]
                
                do {
                    call.responseObject = try decoder?.decode(callData!)
                } catch {
                    dispatchQueue.async {
                        call.failureBlock?(NixError.responseParseError)
                        call.finalBlock?(false)
                    }
                    return
                }
            }
        }
        
        // There's a chance that lack of error doesn't mean there isn't one
        let realError = call.errorDecoding.decode(response: call.response, error: error, data: callData)
        call.data = callData
        if let realLogger = logger {
            dispatchQueue.async { [weak self] in
                if let s = self {
                    realLogger.finished(manager: s, call: call, withError: realError)
                }
            }
        }
        
        close(call: call, error: realError, data: callData)
        // Second - we need to check if that's over or not

    }
    
    private func close(call: ServerCall, error: Error?, data: Data?) {
        
        if let continuityCall = call.onFinish(error: error) {
            continuityCall.finalBlock = call.finalBlock
            continuityCall.successBlock = call.successBlock
            continuityCall.failureBlock = call.failureBlock
            continuityCall.userData = call.userData
            
            DispatchQueue.main.async {
                try? self.execute(continuityCall)
            }
        } else {
            dispatchQueue.async {
                if let error = error {
                    call.failureBlock?(error)
                } else {
                    if call.type == .data {
                        call.successBlock?(call.responseObject ?? data)
                    }
                }
                call.finalBlock?(error == nil)
            }
        }
    }
}
