//
//  OutputStream+Nix.swift
//  Nix
//
//  Created by Bazyli Zygan on 09.04.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import Foundation

extension OutputStream {
    @discardableResult func write(data: Data) -> Int {
        return data.withUnsafeBytes { write($0, maxLength: data.count) }
    }
}
