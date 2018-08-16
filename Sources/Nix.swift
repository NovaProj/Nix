import Foundation

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum NixError: Error {
    case notImplemented
    case responseParseError
    case httpError(Int)
    case wrongURL
    case alreadyRunning
    case notRunning
    case invalidParameters([String: Any])
    case invalidCallMethod
    case timeout(URL)
    case cancelled
    case unknown
}
