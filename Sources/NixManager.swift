import Foundation

open class NixManager: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    
    private var defaultSession: URLSession!
    private var tasks = [URLSessionTask: ServerCall]()
    private var decoders = [String: ResponseDecoding]()
    
    var dispatchQueue = DispatchQueue.main
    var logger: NixLogger?
    
    open static let shared: NixManager = {
        return NixManager()
    }()
    
    open var trustDelegate: NixTrustDelegate? = nil
    open var trustedHosts: [String]?
    
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
        call.task = task
        call.request = request
        logger?.prepared(manager: self, call: call)
        task?.resume()
    }
    
    public func cancel(_ call: ServerCall) throws {
        if call.task != nil {
            call.task?.cancel()
            tasks.removeValue(forKey: call.task!)
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
                disposition = .cancelAuthenticationChallenge
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
        
        // First - let's try to decode response that we have
        call.stream?.close()
        let callData = call.stream?.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
        
        if callData != nil {
            let headers = (call.response as? HTTPURLResponse)?.allHeaderFields
            let cT = headers?["Content-Type"] ?? headers?["Content-type"] ?? headers?["content-type"]
            
            if cT is String {
                // It might be, that cT has additional parameters attached - we ditch them for now
                var contentType = cT as! String
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
        // Second - we need to check if that's over or not
        let continuityCall = call.onFinish(error: realError)
        if continuityCall != nil {
            continuityCall?.finalBlock = call.finalBlock
            continuityCall?.successBlock = call.successBlock
            continuityCall?.failureBlock = call.failureBlock
            continuityCall?.userData = call.userData
            
            DispatchQueue.main.async {
                do {
                    try self.execute(continuityCall!)
                } catch {}
            }
        } else {
            dispatchQueue.async {
                if realError == nil {
                    if call.type == .data {
                        call.successBlock?(call.responseObject ?? callData)
                    }
                } else {
                    call.failureBlock?(realError!)
                }
                call.finalBlock?(realError == nil)
            }
        }
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
}
