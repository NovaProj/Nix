import Foundation

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
    
    private var headerFields: [String: String]?
    private var knownEtag: String?
    
    override open var contentType: String? {
        guard let headers = headerFields else {
            return super.contentType
        }
        return headers["Content-Type"] ?? headers["Content-type"] ?? headers["content-type"]
    }
    
    override open var errorDecoding: ErrorDecoding {
        return CachedErrorDecoding.default
    }
    
    override open func onCallPrepared() -> Bool {
        if let url = request?.url,
            let cachedItem = NixManager.shared.cache?.item(forUrl: url, etag: nil) {
            data = cachedItem.data
            headerFields = cachedItem.responseHeaderFields
            knownEtag = cachedItem.etag
            return false
        }
        return true
    }
    
    override open func onFinish(error: Error?) -> Self? {
        if error == nil {
            // Cache response
            guard let response = response,
                let data = stream?.property(forKey: .dataWrittenToMemoryStreamKey) as? Data ?? data else {
                return nil
            }
            NixManager.shared.cache?.cache(response: response, data: data)
        }
        
        return nil
    }
}
