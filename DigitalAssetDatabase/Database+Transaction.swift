//
//  Database+Transaction.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation

public extension Database {
    public func transactionAsync(block: () throws -> Void, errorBlock: (error: ErrorType) -> Void) -> Void {
        handle!.transactionAsync(queue, block: block, errorBlock: errorBlock);
    }

    public func transactionAsync(block: () throws -> Void) -> Void {
        handle!.transactionAsync(queue, block: block, errorBlock: { (error: ErrorType) in
            print("UNHANDLED ERROR: \(error)\n")
        });
    }
    
    public func transaction(block: () throws -> Void) throws -> Void {
        try handle!.transaction(queue) {
            try block();
        }
    }
    
    public func transaction<T>(block: () throws -> T) throws -> T {
        var result: T?;
    
        try handle!.transaction(queue) {
            result = try block();
        }
        
        return result!;
    }

    public func transaction<T>(block: () throws -> T?) throws -> T? {
        var result: T?;
    
        try handle!.transaction(queue) {
            result = try block();
        }
        
        return result;
    }

    public func assertInTransaction() {
        handle!.assertInTransaction();
    }
}
