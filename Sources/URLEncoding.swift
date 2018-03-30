//
//  URLEncoding.swift
//  Nix
//
//  Created by Bazyli Zygan on 07.09.2017.
//  Copyright © 2017 Nova Project. All rights reserved.
//

import Foundation

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

open class ParameterEncoding {
    
    init() {
        
    }
    
    open func encode(_ call: ServerCall) throws -> URLRequest {
        let url = URL(string: call.baseURLString)
        
        if url == nil {
            throw NixError.wrongURL
        }
        var request = (call.path.count > 0) ? URLRequest(url: url!.appendingPathComponent(call.path)) : URLRequest(url: url!)
        request.httpMethod = call.method.rawValue
        
        // Set User Agent first
        request.addValue(call.userAgent, forHTTPHeaderField: "User-Agent")
        
        if call.headers != nil {
            for (headerKey, headerValue) in call.headers! {
                request.setValue(headerValue, forHTTPHeaderField: headerKey);
            }
        }
        
        return request
    }
}

open class URLEncoding: ParameterEncoding {
    
    private var allowedCharacterSet = CharacterSet.urlQueryAllowed
    
    open static var `default`: URLEncoding { return URLEncoding() }
    
    override init() {
        super.init()
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
    }
    
    open override func encode(_ call: ServerCall) throws -> URLRequest {
        
        var request = try super.encode(call)
        
        
        var queryString = ""
        var components = [String]()
        if call.parameters != nil {
            for (key,value) in call.parameters! {
                if let value = value as? NSNumber {
                    if value.isBool {
                        components.append("\(escape(key))=\(escape((value.boolValue ? "1" : "0")))")
                    } else {
                        components.append("\(escape(key))=\(escape("\(value)"))")
                    }
                } else if let bool = value as? Bool {
                    components.append("\(escape(key))=\(escape((bool ? "1" : "0")))")
                } else {
                    components.append("\(escape(key))=\(escape("\(value)"))")
                }
            }
            
            queryString = components.joined(separator: "&")
            
            if queryString.count > 0 {
                let redefinedUrl = URL(string: request.url!.absoluteString + "?" + queryString)
                request.url = redefinedUrl
            }
        }
        
        return request
    }
    
    private func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }
}
