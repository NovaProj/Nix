import Foundation

internal let mimeTypes = [
    "html": "text/html",
    "htm": "text/html",
    "shtml": "text/html",
    "css": "text/css",
    "xml": "text/xml",
    "gif": "image/gif",
    "jpeg": "image/jpeg",
    "jpg": "image/jpeg",
    "js": "application/javascript",
    "atom": "application/atom+xml",
    "rss": "application/rss+xml",
    "mml": "text/mathml",
    "txt": "text/plain",
    "jad": "text/vnd.sun.j2me.app-descriptor",
    "wml": "text/vnd.wap.wml",
    "htc": "text/x-component",
    "png": "image/png",
    "tif": "image/tiff",
    "tiff": "image/tiff",
    "wbmp": "image/vnd.wap.wbmp",
    "ico": "image/x-icon",
    "jng": "image/x-jng",
    "bmp": "image/x-ms-bmp",
    "svg": "image/svg+xml",
    "svgz": "image/svg+xml",
    "webp": "image/webp",
    "woff": "application/font-woff",
    "jar": "application/java-archive",
    "war": "application/java-archive",
    "ear": "application/java-archive",
    "json": "application/json",
    "hqx": "application/mac-binhex40",
    "doc": "application/msword",
    "pdf": "application/pdf",
    "ps": "application/postscript",
    "eps": "application/postscript",
    "ai": "application/postscript",
    "rtf": "application/rtf",
    "m3u8": "application/vnd.apple.mpegurl",
    "xls": "application/vnd.ms-excel",
    "eot": "application/vnd.ms-fontobject",
    "ppt": "application/vnd.ms-powerpoint",
    "wmlc": "application/vnd.wap.wmlc",
    "kml": "application/vnd.google-earth.kml+xml",
    "kmz": "application/vnd.google-earth.kmz",
    "7z": "application/x-7z-compressed",
    "cco": "application/x-cocoa",
    "jardiff": "application/x-java-archive-diff",
    "jnlp": "application/x-java-jnlp-file",
    "run": "application/x-makeself",
    "pl": "application/x-perl",
    "pm": "application/x-perl",
    "prc": "application/x-pilot",
    "pdb": "application/x-pilot",
    "rar": "application/x-rar-compressed",
    "rpm": "application/x-redhat-package-manager",
    "sea": "application/x-sea",
    "swf": "application/x-shockwave-flash",
    "sit": "application/x-stuffit",
    "tcl": "application/x-tcl",
    "tk": "application/x-tcl",
    "der": "application/x-x509-ca-cert",
    "pem": "application/x-x509-ca-cert",
    "crt": "application/x-x509-ca-cert",
    "xpi": "application/x-xpinstall",
    "xhtml": "application/xhtml+xml",
    "xspf": "application/xspf+xml",
    "zip": "application/zip",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "mid": "audio/midi",
    "midi": "audio/midi",
    "kar": "audio/midi",
    "mp3": "audio/mpeg",
    "ogg": "audio/ogg",
    "m4a": "audio/x-m4a",
    "ra": "audio/x-realaudio",
    "3gpp": "video/3gpp",
    "3gp": "video/3gpp",
    "ts": "video/mp2t",
    "mp4": "video/mp4",
    "mpeg": "video/mpeg",
    "mpg": "video/mpeg",
    "mov": "video/quicktime",
    "webm": "video/webm",
    "flv": "video/x-flv",
    "m4v": "video/x-m4v",
    "mng": "video/x-mng",
    "asx": "video/x-ms-asf",
    "asf": "video/x-ms-asf",
    "wmv": "video/x-ms-wmv",
    "avi": "video/x-msvideo"
]

open class MultipartFormDataStream: InputStream, StreamDelegate {
    private var streams = [InputStream]()
    
    let boundary: String = "NixBoundary" + String(randomWithLength: 20)
    let contentSize: Int64
    
    override open var hasBytesAvailable: Bool {
        if let stream = streams.first {
            return stream.hasBytesAvailable
        } else {
            return false
        }
    }
    
    private var _delegate: StreamDelegate?
    override open var delegate: StreamDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
            streams.first?.delegate = self
        }
    }
    
    override open var streamStatus: Stream.Status {
        return streams.first?.streamStatus ?? .atEnd
    }
    
    override open var streamError: Error? {
        return streams.first?.streamError
    }
    
    init(_ parameters: [String: Any]) throws {
        
        // Right! In order to do it right, we need to prepare all
        // Parameters to be read
        // That means creating headers for every each one of them
        // And if one of them is.. well... bad, we need to throw an error
        var first = true
        var contentLength: Int64 = 0
        for (key, value) in parameters {
            var stream: InputStream? = nil
            var filename: String? = nil
            var contentType: String? = nil
            
            var data: Data? = nil
            if let bool = value as? Bool {
                data = ((bool) ? "true" : "false").data(using: .utf8) ?? Data()
                
            } else if let number = value as? NSNumber {
                data = number.stringValue.data(using: .utf8) ?? Data()
            } else if let string = value as? String {
                data = string.data(using: .utf8) ?? Data()
            } else if let theData = value as? Data {
                data = theData
            } else  if let fileUrl = value as? URL {
                if fileUrl.isFileURL {
                    do {
                        contentLength += try FileManager.default.attributesOfItem(atPath: fileUrl.path)[FileAttributeKey.size] as! Int64
                    } catch {}
                    filename = fileUrl.lastPathComponent
                    stream = InputStream(url: fileUrl)
                    contentType = mimeTypes[fileUrl.pathExtension] ?? "application/octet-stream"
                }
            } else if let theStream = value as? InputStream {
                stream = theStream
            }
            
            if data != nil {
                contentLength += Int64(data!.count)
                stream = InputStream(data: data!)
            }
            
            if stream == nil {
                throw NixError.invalidParameters([key: value])
            } else {
                var headerString = ""
                
                if first {
                    first = false
                } else {
                    headerString += "\r\n"
                }
                headerString += "--\(boundary)\r\n"
                
                headerString += "Content-Disposition: form-data; name=\"\(key)\""
                if filename != nil {
                    headerString += "; filename=\"\(filename!)\""
                }
                headerString += "\r\n"
                if contentType != nil {
                    headerString += "Content-Type: \(contentType!)\r\n"
                }
                headerString += "\r\n"

                let headerData = headerString.data(using: .utf8) ?? Data()
                
                contentLength += Int64(headerData.count)
                
                let headerStream = InputStream(data: headerData)
                streams.append(headerStream)
                streams.append(stream!)
            }
        }
        
        // Last but not least - we need to append final boundary
        let finalData = "\r\n--\(boundary)--".data(using: .utf8) ?? Data()
        contentLength += Int64(finalData.count)
        streams.append(InputStream(data: finalData))
        contentSize = contentLength
        
        super.init(data: Data())
    }
    
    override open func open() {
        streams.first?.open()
    }
    
    override open func close() {
        streams.first?.close()
    }
    
    override open func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        for s in streams {
            s.schedule(in: aRunLoop, forMode: mode)
        }
    }
    
    override open func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        for s in streams {
            s.remove(from: aRunLoop, forMode: mode)
        }
    }
    
    override open func property(forKey key: Stream.PropertyKey) -> Any? {
        return streams.first?.property(forKey: key)
    }
    
    override open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        
        var readLen: Int = 0
        repeat {
             readLen = streams.first?.read(buffer, maxLength: len) ?? 0
        
            switchStreamsIfNeeded()
        } while (readLen == 0 && streams.count > 1)

        return readLen
    }
    
    open func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
            case .errorOccurred:
                _delegate?.stream?(self, handle: .errorOccurred)
                break
            default:
                break
        }
    }
    
     @discardableResult private func switchStreamsIfNeeded(_ force: Bool = false) -> Bool {
        if (!(streams.first?.hasBytesAvailable ?? false) || force) && streams.count > 1 {
            streams.first?.delegate = nil
            streams.first?.close()
            streams.removeFirst()
            streams.first?.open()
            streams.first?.delegate = self
            return true
        }
        return false
    }
}

open class MultipartFormDataEncoding: ParameterEncoding {

    public static var `default`: MultipartFormDataEncoding { return MultipartFormDataEncoding() }
    
    open override func encode(_ call: ServerCall) throws -> URLRequest {
        
        
        // We need to create a proper stream for encoding data. Mainly to allow users to send streams using multipart/form-data
        // In order to do it correctly, whole thing has to be a stream.
        // In other words - here we just check if all parameters sent here are proper and then we pass a stream to
        // request itself so it can handle it as it wishes
        var request = try super.encode(call)
        
        if call.method == .get {
            throw NixError.invalidCallMethod
        }
        
        if call.parameters?.count ?? 0 == 0 {
            throw NixError.invalidParameters([String: Any]())
        }
        
        let stream = try MultipartFormDataStream(call.parameters!)
        request.addValue("multipart/form-data; boundary=\(stream.boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("\(stream.contentSize)", forHTTPHeaderField: "Content-Length")
        request.httpBodyStream = stream
        
        return request
    }
}
