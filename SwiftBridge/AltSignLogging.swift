//
//  AltSignLogging.swift
//  AltSign
//
//  Created by Magesh K on 28/06/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation

public enum AltSignLogging {
    public private(set) static var isLoggingEnabled = false

    public static func setLogging(_ enabled: Bool) {
        isLoggingEnabled = enabled
    }
}

@inline(__always)
public func debugLog(_ text: String) {
    print(text)
}

@inline(__always)
public func verboseLog(_ text: String) {
    if AltSignLogging.isLoggingEnabled {
        print(text)
    }
}
