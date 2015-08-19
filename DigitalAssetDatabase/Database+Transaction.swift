//
//  Database+Transaction.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation

public extension Database {
/*
    internal func transactionAsync(block: () throws -> Void, errorBlock: (error: ErrorType) -> Void) -> Void {
        handle!.transactionAsync(queue, block: block, errorBlock: errorBlock);
    }

    internal func transactionAsync(block: () throws -> Void) -> Void {
        handle!.transactionAsync(queue, block: block, errorBlock: { (error: ErrorType) in
            print("UNHANDLED ERROR: \(error)\n")
        });
    }
    
    internal func transaction(block: () throws -> Void) throws -> Void {
        try handle!.transaction(queue) {
            try block();
        }
    }
    
    internal func transaction<T>(block: () throws -> T) throws -> T {
        var result: T?;
    
        try handle!.transaction(queue) {
            result = try block();
        }
        
        return result!;
    }

    internal func transaction<T>(block: () throws -> T?) throws -> T? {
        var result: T?;
    
        try handle!.transaction(queue) {
            result = try block();
        }
        
        return result;
    }

    internal func assertInTransaction() {
        handle!.assertInTransaction();
    }*/
}
