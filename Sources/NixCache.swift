import Foundation

public struct CachedItem: Codable {
    let etag: String?
    let expires: Date
    let responseHeaderFields: [String:String]
    let data: Data
}

public protocol NixCache {
    func item(forUrl: URL, etag: String?) -> CachedItem?
    func cache(response: URLResponse, data: Data)
}
