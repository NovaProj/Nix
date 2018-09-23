import Security

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(self.startIndex, offsetBy: r.lowerBound)
        let end = self.index(self.startIndex, offsetBy: r.upperBound)
        return String(self[start..<end])
    }
    
    init(randomWithLength length: Int) {
        var randomBytes = [UInt8](repeating: 0, count: length)
        
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
        
        self.init(randomBytes.map({String(format: "%02hhx", $0)}).joined(separator: ""))
    }
    

}
