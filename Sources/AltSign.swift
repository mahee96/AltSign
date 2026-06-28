//
//  AltSign.swift
//  AltSign
//
//  Created by Magesh K on 28/06/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Foundation

public enum AltSign {
    public private(set) static var isLoggingEnabled = false

    public static func setLogging(_ enabled: Bool) {
        isLoggingEnabled = enabled
    }
}

@inline(__always)
func debugLog(_ text: String) {
    print(text)
}

@inline(__always)
func verboseLog(_ text: String) {
    if AltSign.isLoggingEnabled {
        print(text)
    }
}
