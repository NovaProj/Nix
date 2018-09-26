import Foundation

public class L1L2Cache: L1Cache {
    
    private var cacheFolderUrl: URL? = URL.cacheFolderUrl()
    private var sizeLimit: Int?
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var justLoadedHash: String?
    
    private struct FileMetaData {
        let url: URL
        let lastDate: Date
        let size: UInt64
    }
    
    init(cacheFolder: URL? = nil, sizeLimit limit: Int? = nil) {
        super.init(limit: 20)
        if let folder = cacheFolderUrl {
            self.cacheFolderUrl = folder
        }
        sizeLimit = limit
    }
    
    public override func add(item: CachedItem, forUrl url: URL) {
        super.add(item: item, forUrl: url)
        
        let hash = MD5(string: url.absoluteString).toString()
        
        guard justLoadedHash != hash else {
            return
        }
        
        if let localUrl = cacheFolderUrl?.appendingPathComponent(hash) {
            do {
                try encoder.encode(item).write(to: localUrl)
            } catch {
                print("Error while trying to encode item \(url)")
            }
        }
        controlCapacity()
    }
    
    public override func item(forUrl url: URL, etag: String?) -> CachedItem? {
        
        let hash = MD5(string: url.absoluteString).toString()
        guard let localUrl = cacheFolderUrl?.appendingPathComponent(hash) else {
            return nil
        }
        do {
            try update(itemAtUrl: localUrl)
        } catch {
            print("Cannot update access time of given item")
        }
        
        return super.item(forUrl: url, etag: etag) ?? itemFromDisk(forUrl: url, etag: etag)
    }
    
    private func itemFromDisk(forUrl url: URL, etag: String?) -> CachedItem? {
        let hash = MD5(string: url.absoluteString).toString()
        guard let localUrl = cacheFolderUrl?.appendingPathComponent(hash) else {
            return nil
        }
        
        if FileManager.default.fileExists(atPath: localUrl.path),
            let fileData = FileManager.default.contents(atPath: localUrl.path) {
            
            do {
                let item = try decoder.decode(CachedItem.self, from: fileData)
                if item.expires >= Date() {
                    l1Save(item: item, forUrl: url)
                    try update(itemAtUrl: url)
                    return item
                } else {
                    try FileManager.default.removeItem(at: localUrl)
                }
            } catch {
                print("Failed to decode file for url \(url)")
            }
        }
        return nil
    }
    
    private func l1Save(item: CachedItem, forUrl url: URL) {
        justLoadedHash = MD5(string: url.absoluteString).toString()
        add(item: item, forUrl: url)
        justLoadedHash = nil
    }
    
    private func update(itemAtUrl url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.setAttributes([FileAttributeKey.modificationDate: Date()], ofItemAtPath: url.path)
        }
    }
    
    private func controlCapacity() {
        guard let limit = sizeLimit, let cacheUrl = cacheFolderUrl else {
            return
        }
        
        do {
            var size: UInt64 = 0
            let fileList = try FileManager.default.contentsOfDirectory(atPath: cacheUrl.path)
            let files: [FileMetaData] = try fileList.compactMap {
                let attributes = try FileManager.default.attributesOfItem(atPath: cacheUrl.appendingPathComponent($0).path)
                if let sizeNumber = attributes[FileAttributeKey.size] as? NSNumber,
                    let accessDate = attributes[FileAttributeKey.modificationDate] as? Date {
                    let fileSize = sizeNumber.uint64Value
                    size = size + fileSize
                    return FileMetaData(url: cacheUrl.appendingPathComponent($0), lastDate: accessDate, size: size)
                }
                    return nil
            }.sorted {
                return $0.lastDate < $1.lastDate
            }
            if size > limit {
                for file in files {
                    try FileManager.default.removeItem(at: file.url)
                    size = size - file.size
                    if size <= limit {
                        break
                    }
                }
            }
        } catch {
        }
    }
}
