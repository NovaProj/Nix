import Foundation

extension OutputStream {
    @discardableResult func write(data: Data) -> Int {
        return data.withUnsafeBytes { write($0, maxLength: data.count) }
    }
}
