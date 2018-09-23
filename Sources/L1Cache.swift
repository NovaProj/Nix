import Foundation

public class L1Cache: NixCache {
    
    private var l1Cache = [String: CachedItem]()
    private var l1CacheExpiryQueue = [String]()
    
    private var itemLimit: Int
    
    public func cache(response: URLResponse, data: Data) {
        guard let resp = response as? HTTPURLResponse,
            let url = resp.url else {
            return
        }
        
        let etag = (resp.allHeaderFields["etag"] ?? resp.allHeaderFields["Etag"]) as? String
        let hash = MD5(string: url.absoluteString).toString()
        
        // TODO: For now - all cache items will expire after 24 hours
        l1Cache[hash] = CachedItem(etag: etag, expires: Date(timeIntervalSinceNow: 60*60*24), responseHeaderFields: resp.allHeaderFields as? [String:String] ?? [String:String](), data: data)
        l1CacheExpiryQueue.append(hash)
        cleanL1Cache()
    }
    
    public func item(forUrl url: URL, etag: String?) -> CachedItem? {
        let hash = MD5(string: url.absoluteString).toString()
        return l1Cache[hash]
    }
    
    public init(limit: Int = 100) {
        itemLimit = limit
    }
    
    func cleanCache() {
        cleanL1Cache(purge: true)
    }
    
    // MARK: - Privates
    private func cleanL1Cache(purge: Bool = false) {
        if purge {
            l1Cache.removeAll()
            l1CacheExpiryQueue.removeAll()
        } else {
            // TODO: Because expiry date still doesn't matter, we simply remove the oldest
            while l1CacheExpiryQueue.count > itemLimit {
                l1Cache.removeValue(forKey: l1CacheExpiryQueue.removeLast())
            }
        }
    }
}
