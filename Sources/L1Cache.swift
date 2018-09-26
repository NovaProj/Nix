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
        let item = CachedItem(etag: etag, expires: Date(timeIntervalSinceNow: 60*60*24), responseHeaderFields: resp.allHeaderFields as? [String:String] ?? [String:String](), data: data)
                
        add(item: item, forUrl: url)
    }
    
    public func item(forUrl url: URL, etag: String?) -> CachedItem? {
        let hash = MD5(string: url.absoluteString).toString()
        if let item = l1Cache[hash] {
            if let index = l1CacheExpiryQueue.lastIndex(of: hash) {
                l1CacheExpiryQueue.remove(at: index)
                l1CacheExpiryQueue.append(hash)
            }
            return item
        }
        return nil
    }
    
    public init(limit: Int = 100) {
        itemLimit = limit
    }
    
    public func cleanCache() {
        cleanL1Cache(purge: true)
    }
    
    public func add(item: CachedItem, forUrl url: URL) {
        let hash = MD5(string: url.absoluteString).toString()
        l1Cache[hash] = item
        l1CacheExpiryQueue.append(hash)
        cleanL1Cache()
    }
    
    // MARK: - Privates
    private func cleanL1Cache(purge: Bool = false) {
        if purge {
            l1Cache.removeAll()
            l1CacheExpiryQueue.removeAll()
        } else {
            while l1CacheExpiryQueue.count > itemLimit {
                l1Cache.removeValue(forKey: l1CacheExpiryQueue.removeFirst())
            }
        }
    }
}
