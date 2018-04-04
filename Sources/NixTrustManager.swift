//
//  NixTrustDelegate.swift
//  Nix
//
//  Created by Bazyli Zygan on 04.04.2018.
//

import Foundation

public protocol NixTrustDelegate: NSObjectProtocol {
    
    func nixManager(_ nixManager: NixManager, shouldTrustHost: String) -> Bool
}
