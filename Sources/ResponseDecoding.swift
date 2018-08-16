open class ResponseDecoding {
    
    open var contentType: String {
        get {
            return "application/x-octet-stream"
        }
    }
    
    public init() {
        
    }

    open func decode(_ data: Data) throws -> Any? {
        
        return nil
    }
}

open class JSONDecoding: ResponseDecoding {
    
    override open var contentType: String {
        get {
            return "application/json"
        }
    }
    
    override open func decode(_ data: Data) throws -> Any? {
        return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
    }
}

open class XMLDecoding: ResponseDecoding {
    override open var contentType: String {
        get {
            return "application/xml"
        }
    }
    
    override open func decode(_ data: Data) throws -> Any? {
        return XMLParser(data: data)
    }
}
