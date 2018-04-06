//
//  NixTrustDelegate.swift
//  Nix
//
//  Created by Bazyli Zygan on 06.04.2018.
//  Copyright © 2018 Nova Project. All rights reserved.
//

import Foundation

public protocol NixTrustDelegate: NSObjectProtocol {
    
    func nixManager(_ nixManager: NixManager, shouldTrustHost: String) -> Bool
}
