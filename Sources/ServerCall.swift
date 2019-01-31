import Foundation

open class ServerCall {

    public enum Status: String {
        case idle = "idle"
        case running = "running"
        case finished = "finished"
        case cancelled = "cancelled"
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
    
    open var responseDecoding: ResponseDecoding? {
        get {
            return nil
        }
    }
    
    open var errorDecoding: ErrorDecoding {
        get {
            return HTTPErrorDecoder.default
        }
    }
    
    open var isValid: Bool {
        return true
    }
    
    open var status: Status = .idle
    
    open var expectedDataSize: Int64 = 0
    open var receivedDataSize: Int64 = 0
    open var stream: OutputStream?
    open var data: Data? = nil
    open var responseObject: Any?
    open var userData: Any?
    open var request: URLRequest?
    open var response: URLResponse?
    
    open var successBlock: ((Any?) -> Void)?
    open var failureBlock: ((Error) -> Void)?
    open var finalBlock: ((Bool) -> Void)?
    open var progressBlock: ((Int64, Int64) -> Void)?
    
    open var id: String
    open var task: URLSessionTask?
    
    open var contentType: String? {
        guard let headers = (response as? HTTPURLResponse)?.allHeaderFields else {
            return nil
        }
        
        return headers["Content-Type"] as? String ?? headers["Content-type"] as? String ?? headers["content-type"] as? String
    }
    
    static public func ==(left: ServerCall, right: ServerCall) -> Bool {
        return left.id == right.id
    }

    public init(executeNow: Bool = true) {
        id = String(randomWithLength: 16)
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
        guard status == .idle else {
            if status == .cancelled {
                throw NixError.cancelled
            } else {
                throw NixError.alreadyRunning
            }
        }
        
        try NixManager.shared.execute(self)
    }
    
    open func cancel() throws {
        guard status != .finished else {
            throw NixError.notRunning
        }
        status = .cancelled
        try NixManager.shared.cancel(self)
    }
    
    open func onCallPrepared() -> Bool {
        return true
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
    
    @discardableResult open func progress(_ progress: @escaping (Int64, Int64) -> Void) -> Self {
        
        progressBlock = progress
        return self
    }

    
    @discardableResult open func success(_ success: @escaping (Any?) -> Void) -> Self {
        
        successBlock = success
        return self
    }

    @discardableResult open func failure(_ failure: @escaping (Error) -> Void) -> Self {
        
        failureBlock = failure
        return self
    }
    
    @discardableResult open func finally(_ finally: @escaping (Bool) -> Void) -> Self {
        
        finalBlock = finally
        return self
    }
}
