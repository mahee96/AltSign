
//
//  ALTCapabilities.swift
//  AltSign
//
//  Swift port of ALTCapabilities.h/.m
//  Behavior preserved 1:1
//

import Foundation

public typealias ALTEntitlement = String
public typealias ALTCapability = String
public typealias ALTFeature = String

// MARK: Entitlements

public let ALTEntitlementApplicationIdentifier: ALTEntitlement = "application-identifier"
public let ALTEntitlementKeychainAccessGroups: ALTEntitlement = "keychain-access-groups"
public let ALTEntitlementAppGroups: ALTEntitlement = "com.apple.security.application-groups"
public let ALTEntitlementGetTaskAllow: ALTEntitlement = "get-task-allow"
public let ALTEntitlementIncreasedMemoryLimit: ALTEntitlement = "com.apple.developer.kernel.increased-memory-limit"
public let ALTEntitlementTeamIdentifier: ALTEntitlement = "com.apple.developer.team-identifier"
public let ALTEntitlementInterAppAudio: ALTEntitlement = "inter-app-audio"
public let ALTEntitlementIncreasedDebuggingMemoryLimit: ALTEntitlement = "com.apple.developer.kernel.increased-debugging-memory-limit"
public let ALTEntitlementExtendedVirtualAddressing: ALTEntitlement = "com.apple.developer.kernel.extended-virtual-addressing"

// MARK: Capabilities

public let ALTCapabilityIncreasedMemoryLimit: ALTCapability = "INCREASED_MEMORY_LIMIT"
public let ALTCapabilityIncreasedDebuggingMemoryLimit: ALTCapability = "INCREASED_MEMORY_LIMIT_DEBUGGING"
public let ALTCapabilityExtendedVirtualAddressing: ALTCapability = "EXTENDED_VIRTUAL_ADDRESSING"

// MARK: Features

public let ALTFeatureGameCenter: ALTFeature = "gameCenter"
public let ALTFeatureAppGroups: ALTFeature = "APG3427HIY"
public let ALTFeatureInterAppAudio: ALTFeature = "IAD53UNK2F"

// MARK: Feature ↔ Entitlement Mapping

@inlinable
public func ALTEntitlementForFeature(_ feature: ALTFeature) -> ALTEntitlement? {
    if feature == ALTFeatureAppGroups {
        return ALTEntitlementAppGroups
    } else if feature == ALTFeatureInterAppAudio {
        return ALTEntitlementInterAppAudio
    }
    return nil
}

@inlinable
public func ALTFeatureForEntitlement(_ entitlement: ALTEntitlement) -> ALTFeature? {
    if entitlement == ALTEntitlementAppGroups {
        return ALTFeatureAppGroups
    } else if entitlement == ALTEntitlementInterAppAudio {
        return ALTFeatureInterAppAudio
    }
    return nil
}

// MARK: Free Developer Entitlement Rules

@inlinable
public func ALTFreeDeveloperCanUseEntitlement(_ entitlement: ALTEntitlement) -> Bool {

    switch entitlement {
    case ALTEntitlementAppGroups,
         ALTEntitlementInterAppAudio,
         ALTEntitlementGetTaskAllow,
         ALTEntitlementIncreasedMemoryLimit,
         ALTEntitlementTeamIdentifier,
         ALTEntitlementKeychainAccessGroups,
         ALTEntitlementApplicationIdentifier:
        return true

    default:
        return false
    }
}
