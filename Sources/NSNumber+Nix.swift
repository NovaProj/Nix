//
//  NSNumber+Nix.swift
//  Nix
//
//  Created by Bazyli Zygan on 06.04.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import Foundation

extension NSNumber {
    var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}
