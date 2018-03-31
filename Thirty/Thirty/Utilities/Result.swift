//
//  Result.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}

extension Result {
    public var isSuccess: Bool {
        guard case .success(_) = self else { return false }
        return true
    }
    
    public var isFailure: Bool {
        guard case .failure(_) = self else { return false }
        return true
    }
}

extension Result {
    public var value: T? {
        guard case let .success(value) = self else { return nil }
        return value
    }
    
    public var error: Error? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

extension Result where T == Void {
    static var success: Result {
        return .success(())
    }
}
