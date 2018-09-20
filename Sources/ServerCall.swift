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
        if status != .idle {
            throw NixError.alreadyRunning
        }
        
        try NixManager.shared.execute(self)
    }
    
    open func cancel() throws {
        if status != .running {
            throw NixError.notRunning
        }
        
        try NixManager.shared.cancel(self)
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
