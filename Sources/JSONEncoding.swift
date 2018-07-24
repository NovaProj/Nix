//
//  JSONEncoding.swift
//  Nix
//
//  Created by Bazyli Zygan on 20.07.2018.
//

import Foundation

class JSONEncoding: ParameterEncoding {
    
    public static var `default`: JSONEncoding { return JSONEncoding() }
    
    open override func encode(_ call: ServerCall) throws -> URLRequest {
        var request = try super.encode(call)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let params = call.parameters {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        }
        return request
    }
}
