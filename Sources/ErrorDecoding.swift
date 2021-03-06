import Foundation

public protocol ErrorDecoding {
    func decode(response: URLResponse?, error: Error?, data: Data?) -> Error?
}

open class HTTPErrorDecoder: ErrorDecoding {

    public static var `default`: ErrorDecoding { return HTTPErrorDecoder() }
    
    open func decode(response: URLResponse?, error: Error?, data: Data?) -> Error? {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        return error ?? ((statusCode > 299) ? NixError.httpError(statusCode) : nil)
    }
}
