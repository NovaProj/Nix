import UIKit

class CachedErrorDecoding: ErrorDecoding {
    
    public static var `default`: CachedErrorDecoding { return CachedErrorDecoding() }
    
    func decode(response: URLResponse?, error: Error?, data: Data?) -> Error? {
        if data != nil {
            return nil
        }
        
        return error
    }
}

open class CachedCall: ServerCall {
    
    private struct CachedData {
        let etag: String
        let expires: Date
        let data: Data
    }
    
    private static var cachedResponses = [String: CachedData]()
   
//    private let formatter = DateFormatter()
    override open var errorDecoding: ErrorDecoding {
        return CachedErrorDecoding.default
    }
    
    override open func onResponseReceived(_ response: URLResponse) -> Bool {
        guard let resp = response as? HTTPURLResponse,
            let lengthString = resp.allHeaderFields["Content-Length"] as? String,
            let length = Int(lengthString),
            let etag = (resp.allHeaderFields["etag"] ?? resp.allHeaderFields["Etag"]) as? String else {
                return true
        }
        
        if let cachedItem = CachedCall.cachedResponses[etag] {
            if cachedItem.data.count == length {
                // TODO: Check if it haven't expired
                data = cachedItem.data
                return false
            }
        }
        
        return true
    }
    
    override open func onFinish(error: Error?) -> ServerCall? {
        if error == nil {
            // Cache response
            guard let resp = response as? HTTPURLResponse,
                let etag = (resp.allHeaderFields["etag"] ?? resp.allHeaderFields["Etag"]) as? String,
                let data = data else {
                    return nil
            }
            CachedCall.cachedResponses[etag] = CachedData(etag: etag, expires: Date(), data: data)
        }
        
        return nil
    }
    
//    private func parseDate(fromString string: String) -> Date? {
//    }
}
