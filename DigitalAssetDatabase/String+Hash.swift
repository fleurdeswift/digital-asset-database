//
//  String+Hash.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation
import CommonCrypto

public extension String {
    public func sha256() -> String {
        let data = (self as NSString).dataUsingEncoding(NSUTF8StringEncoding)!;
        var hash = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
        
        CC_SHA256(data.bytes, CC_LONG(data.length), &hash)
        
        var output: String = "";
        
        for byte in hash {
            output += byte.asHexString;
        }
        
        return output
    }
}
