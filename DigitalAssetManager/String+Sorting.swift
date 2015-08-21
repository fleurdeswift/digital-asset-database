//
//  String+Sorting.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation

infix operator ^< {
    associativity right
    precedence 155
}


infix operator ^== {
    associativity right
    precedence 155
}

func ^< (s1: String, s2: String) -> Bool {
    return s1.localizedCaseInsensitiveCompare(s2) == NSComparisonResult.OrderedAscending;
}

func ^== (s1: String, s2: String) -> Bool {
    return s1.localizedCaseInsensitiveCompare(s2) == NSComparisonResult.OrderedSame;
}
