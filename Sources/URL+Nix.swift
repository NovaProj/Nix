extension URL {
    
    var baseURLString: String? {
        get {
            var urlString = self.absoluteString
            // Strip parameters if they are there
            let paramsRange = urlString.range(of: "?")
            if !(paramsRange?.isEmpty ?? true) {
                urlString = String(urlString[..<paramsRange!.lowerBound])
            }
            var schemeLen = self.scheme?.count ?? 0
            if schemeLen > 0 {
                schemeLen += 3
            }
            // Simple sanity - just in case
            if schemeLen > 0 {
                urlString = urlString[schemeLen..<urlString.count]
            }
            
            let pathRange = urlString.range(of: "/")
            if !(pathRange?.isEmpty ?? true) {
                urlString = String(urlString[..<pathRange!.lowerBound])
            }
            if self.scheme != nil {
                return self.scheme! + "://" + urlString
            } else {
                return urlString
            }
        }
    }
    
    static func cacheFolderUrl() -> URL? {
        if let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            return url
        }
        return nil
    }
}
