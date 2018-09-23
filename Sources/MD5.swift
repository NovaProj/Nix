import Foundation


class MD5 {
    
    private let string: String
    
    private let hexTab: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    
    init(string: String) {
        self.string = string
    }
    
    func toString() -> String {
        return hex_md5(string)
    }
    
    private func hex_md5(_ input: String) -> String {
        return rstr2hex(rstr_md5(str2rstr_utf8(input)))
    }
    
    private func str2rstr_utf8(_ input: String) -> [CUnsignedChar] {
        return Array(input.utf8)
    }
    
    private func rstr2tr(_ input: [CUnsignedChar]) -> String {
        var output: String = ""
        
        input.forEach { output.append(String(UnicodeScalar($0))) }
        
        return output
    }
    
    private func rstr2hex(_ input: [CUnsignedChar]) -> String {
        var output: [Character] = []
        
        input.forEach {
            let value1 = hexTab[Int(($0 >> 4) & 0x0F)]
            let value2 = hexTab[Int(Int32($0) & 0x0F)]
            
            output.append(value1)
            output.append(value2)
        }
        
        return String(output)
    }
    
    private func rstr2binl(_ input: [CUnsignedChar]) -> [Int32] {
        var output: [Int: Int32] = [:]
        
        for i in stride(from: 0, to: input.count * 8, by: 8) {
            let value: Int32 = (Int32(input[i/8]) & 0xFF) << (Int32(i) % 32)
            
            output[i >> 5] = unwrap(output[i >> 5]) | value
        }
        
        return dictionary2array(output)
    }
    
    private func binl2rstr(_ input: [Int32]) -> [CUnsignedChar] {
        var output: [CUnsignedChar] = []
        
        stride(from: 0, to: input.count * 32, by: 8).forEach {
            output.append(CUnsignedChar(zeroFillRightShift(input[$0>>5], Int32($0 % 32)) & 0xFF))
        }
        
        return output
    }
    
    private func rstr_md5(_ input: [CUnsignedChar]) -> [CUnsignedChar] {
        return binl2rstr(binl_md5(rstr2binl(input), input.count * 8))
    }
    
    private func safe_add(_ x: Int32, _ y: Int32) -> Int32 {
        return x &+ y
    }
    
    private func bit_rol(_ num: Int32, _ cnt: Int32) -> Int32 {
        return (num << cnt) | zeroFillRightShift(num, (32 - cnt))
    }
    
    
    private func md5_cmn(_ q: Int32, _ a: Int32, _ b: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b)
    }
    
    private func md5_ff(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn((b & c) | ((~b) & d), a, b, x, s, t)
    }
    
    private func md5_gg(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn((b & d) | (c & (~d)), a, b, x, s, t)
    }
    
    private func md5_hh(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn(b ^ c ^ d, a, b, x, s, t)
    }
    
    private func md5_ii(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32, _ s: Int32, _ t: Int32) -> Int32 {
        return md5_cmn(c ^ (b | (~d)), a, b, x, s, t)
    }

    private func binl_md5(_ input: [Int32], _ len: Int) -> [Int32] {
        var x: [Int: Int32] = [:]
        for (index, value) in input.enumerated() {
            x[index] = value
        }
        
        let value: Int32 = 0x80 << Int32((len) % 32)
        x[len >> 5] = unwrap(x[len >> 5]) | value
        
        let index = (((len + 64) >> 9) << 4) + 14
        x[index] = unwrap(x[index]) | Int32(len)
        
        var a: Int32 =  1732584193
        var b: Int32 = -271733879
        var c: Int32 = -1732584194
        var d: Int32 =  271733878
        
        stride(from: 0, to: length(x), by: 16).forEach {
            let olda: Int32 = a
            let oldb: Int32 = b
            let oldc: Int32 = c
            let oldd: Int32 = d
            
            a = md5_ff(a, b, c, d, unwrap(x[$0 + 0]), 7 , -680876936)
            d = md5_ff(d, a, b, c, unwrap(x[$0 + 1]), 12, -389564586)
            c = md5_ff(c, d, a, b, unwrap(x[$0 + 2]), 17,  606105819)
            b = md5_ff(b, c, d, a, unwrap(x[$0 + 3]), 22, -1044525330)
            a = md5_ff(a, b, c, d, unwrap(x[$0 + 4]), 7 , -176418897)
            d = md5_ff(d, a, b, c, unwrap(x[$0 + 5]), 12,  1200080426)
            c = md5_ff(c, d, a, b, unwrap(x[$0 + 6]), 17, -1473231341)
            b = md5_ff(b, c, d, a, unwrap(x[$0 + 7]), 22, -45705983)
            a = md5_ff(a, b, c, d, unwrap(x[$0 + 8]), 7 ,  1770035416)
            d = md5_ff(d, a, b, c, unwrap(x[$0 + 9]), 12, -1958414417)
            c = md5_ff(c, d, a, b, unwrap(x[$0 + 10]), 17, -42063)
            b = md5_ff(b, c, d, a, unwrap(x[$0 + 11]), 22, -1990404162)
            a = md5_ff(a, b, c, d, unwrap(x[$0 + 12]), 7 ,  1804603682)
            d = md5_ff(d, a, b, c, unwrap(x[$0 + 13]), 12, -40341101)
            c = md5_ff(c, d, a, b, unwrap(x[$0 + 14]), 17, -1502002290)
            b = md5_ff(b, c, d, a, unwrap(x[$0 + 15]), 22,  1236535329)
            
            a = md5_gg(a, b, c, d, unwrap(x[$0 + 1]), 5 , -165796510)
            d = md5_gg(d, a, b, c, unwrap(x[$0 + 6]), 9 , -1069501632)
            c = md5_gg(c, d, a, b, unwrap(x[$0 + 11]), 14,  643717713)
            b = md5_gg(b, c, d, a, unwrap(x[$0 + 0]), 20, -373897302)
            a = md5_gg(a, b, c, d, unwrap(x[$0 + 5]), 5 , -701558691)
            d = md5_gg(d, a, b, c, unwrap(x[$0 + 10]), 9 ,  38016083)
            c = md5_gg(c, d, a, b, unwrap(x[$0 + 15]), 14, -660478335)
            b = md5_gg(b, c, d, a, unwrap(x[$0 + 4]), 20, -405537848)
            a = md5_gg(a, b, c, d, unwrap(x[$0 + 9]), 5 ,  568446438)
            d = md5_gg(d, a, b, c, unwrap(x[$0 + 14]), 9 , -1019803690)
            c = md5_gg(c, d, a, b, unwrap(x[$0 + 3]), 14, -187363961)
            b = md5_gg(b, c, d, a, unwrap(x[$0 + 8]), 20,  1163531501)
            a = md5_gg(a, b, c, d, unwrap(x[$0 + 13]), 5 , -1444681467)
            d = md5_gg(d, a, b, c, unwrap(x[$0 + 2]), 9 , -51403784)
            c = md5_gg(c, d, a, b, unwrap(x[$0 + 7]), 14,  1735328473)
            b = md5_gg(b, c, d, a, unwrap(x[$0 + 12]), 20, -1926607734)
            
            a = md5_hh(a, b, c, d, unwrap(x[$0 + 5]), 4 , -378558)
            d = md5_hh(d, a, b, c, unwrap(x[$0 + 8]), 11, -2022574463)
            c = md5_hh(c, d, a, b, unwrap(x[$0 + 11]), 16,  1839030562)
            b = md5_hh(b, c, d, a, unwrap(x[$0 + 14]), 23, -35309556)
            a = md5_hh(a, b, c, d, unwrap(x[$0 + 1]), 4 , -1530992060)
            d = md5_hh(d, a, b, c, unwrap(x[$0 + 4]), 11,  1272893353)
            c = md5_hh(c, d, a, b, unwrap(x[$0 + 7]), 16, -155497632)
            b = md5_hh(b, c, d, a, unwrap(x[$0 + 10]), 23, -1094730640)
            a = md5_hh(a, b, c, d, unwrap(x[$0 + 13]), 4 ,  681279174)
            d = md5_hh(d, a, b, c, unwrap(x[$0 + 0]), 11, -358537222)
            c = md5_hh(c, d, a, b, unwrap(x[$0 + 3]), 16, -722521979)
            b = md5_hh(b, c, d, a, unwrap(x[$0 + 6]), 23,  76029189)
            a = md5_hh(a, b, c, d, unwrap(x[$0 + 9]), 4 , -640364487)
            d = md5_hh(d, a, b, c, unwrap(x[$0 + 12]), 11, -421815835)
            c = md5_hh(c, d, a, b, unwrap(x[$0 + 15]), 16,  530742520)
            b = md5_hh(b, c, d, a, unwrap(x[$0 + 2]), 23, -995338651)
            
            a = md5_ii(a, b, c, d, unwrap(x[$0 + 0]), 6 , -198630844)
            d = md5_ii(d, a, b, c, unwrap(x[$0 + 7]), 10,  1126891415)
            c = md5_ii(c, d, a, b, unwrap(x[$0 + 14]), 15, -1416354905)
            b = md5_ii(b, c, d, a, unwrap(x[$0 + 5]), 21, -57434055)
            a = md5_ii(a, b, c, d, unwrap(x[$0 + 12]), 6 ,  1700485571)
            d = md5_ii(d, a, b, c, unwrap(x[$0 + 3]), 10, -1894986606)
            c = md5_ii(c, d, a, b, unwrap(x[$0 + 10]), 15, -1051523)
            b = md5_ii(b, c, d, a, unwrap(x[$0 + 1]), 21, -2054922799)
            a = md5_ii(a, b, c, d, unwrap(x[$0 + 8]), 6 ,  1873313359)
            d = md5_ii(d, a, b, c, unwrap(x[$0 + 15]), 10, -30611744)
            c = md5_ii(c, d, a, b, unwrap(x[$0 + 6]), 15, -1560198380)
            b = md5_ii(b, c, d, a, unwrap(x[$0 + 13]), 21,  1309151649)
            a = md5_ii(a, b, c, d, unwrap(x[$0 + 4]), 6 , -145523070)
            d = md5_ii(d, a, b, c, unwrap(x[$0 + 11]), 10, -1120210379)
            c = md5_ii(c, d, a, b, unwrap(x[$0 + 2]), 15,  718787259)
            b = md5_ii(b, c, d, a, unwrap(x[$0 + 9]), 21, -343485551)
            
            a = safe_add(a, olda)
            b = safe_add(b, oldb)
            c = safe_add(c, oldc)
            d = safe_add(d, oldd)
        }
        
        return [a, b, c, d]
    }
    
    private func length(_ dictionary: [Int: Int32]) -> Int {
        return (dictionary.keys.max() ?? 0) + 1
    }
    
    private func dictionary2array(_ dictionary: [Int: Int32]) -> [Int32] {
        var array = Array<Int32>(repeating: 0, count: dictionary.keys.count)
        
        Array(dictionary.keys).sorted().forEach {
            array[$0] = unwrap(dictionary[$0])
        }
        
        return array
    }
    
    private func unwrap(_ value: Int32?, _ fallback: Int32 = 0) -> Int32 {
        if let value = value {
            return value
        }
        
        return fallback
    }
    
    private func zeroFillRightShift(_ num: Int32, _ count: Int32) -> Int32 {
        let value = UInt32(bitPattern: num) >> UInt32(bitPattern: count)
        return Int32(bitPattern: value)
    }
}
