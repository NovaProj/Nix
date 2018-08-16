import Foundation

open protocol NixLogger: class {
    func prepared(manager: NixManager, call: ServerCall)
    func receivedHeader(manager: NixManager, forCall call: ServerCall)
    func finished(manager: NixManager, call: ServerCall, withError error: Error?)
}
