import Foundation

public protocol NixTrustDelegate: NSObjectProtocol {
    
    func nixManager(_ nixManager: NixManager, shouldTrustHost: String) -> Bool
}
