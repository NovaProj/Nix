//
//  Nix.swift
//  Nix
//
//  Created by Bazyli Zygan on 04.09.2017.
//  Copyright © 2017 Nova Project. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum NixError: Error {
    case notImplemented
    case responseParseError
    case httpError(Int)
    case wrongURL
    case alreadyRunning
    case invalidParameters([String: Any])
    case timeout(URL)
    case unknown
}
