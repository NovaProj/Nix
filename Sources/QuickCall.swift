import Foundation

open class QuickCall: ServerCall {

    override open var baseURLString: String {
        get {
            return url.baseURLString ?? "localhost"
        }
    }
    
    override open var path: String {
        get {
            return url.path
        }
    }
    
    override open var method: HTTPMethod {
        get {
            return callMethod
        }
    }
    
    override open var headers: [String: String]? {
        get {
            return headerAttributes
        }
    }
    
    override open var parameters: [String: Any]? {
        get {
            return callParameters
        }
    }
    
    override open var parameterEncoding: ParameterEncoding {
        get {
            return URLEncoding.default
        }
    }
    
    private var url: URL
    private var headerAttributes: [String: String]? = nil
    private var callMethod: HTTPMethod = .get
    private var callParameters: [String: Any]? = nil
    
    public init(_ url: URL, method: HTTPMethod = .get, parameters: [String:Any]? = nil, headerAttributes: [String: String]? = nil) {
        self.url = url
        self.headerAttributes = headerAttributes
        self.callMethod = method
        self.callParameters = parameters
        super.init()
    }
}
