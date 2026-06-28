import Foundation
import NativeBridge

// MARK: - Callback storage (global, required for C ABI)

private enum _LdidCallbackStorage {
    static var entitlementProvider: ((String) -> String)?
    static var progress: (() -> Void)?
}

// MARK: - C trampolines (MUST be top-level funcs)

@_cdecl("ldid_entitlement_trampoline")
private func ldid_entitlement_trampoline(
    _ cPath: UnsafePointer<CChar>?
) -> UnsafePointer<CChar>? {

    guard
        let cPath,
        let provider = _LdidCallbackStorage.entitlementProvider
    else { return nil }

    let swiftPath = String(cString: cPath)
    let value = provider(swiftPath)

    let duplicated = strdup(value)
    return duplicated.map { UnsafePointer($0) }
}

@_cdecl("ldid_progress_trampoline")
private func ldid_progress_trampoline() {
    _LdidCallbackStorage.progress?()
}

// MARK: - Public Bridge

public enum LdidBridge {

    public enum Error: Swift.Error {
        case invalidPath
        case operationFailed(String)
    }

    // MARK: Read APIs

    public static func entitlements(at url: URL) throws -> String {
        let path = url.path
        print("[AltSign] LdidBridge.entitlements(at: \(path)) started")
        guard !path.isEmpty else {
            print("[AltSign] LdidBridge.entitlements failed: path is empty")
            throw Error.invalidPath
        }

        guard let ptr = path.withCString({ native_bridge_ldid_entitlements($0) }) else {
            print("[AltSign] LdidBridge.entitlements failed: native operation failed")
            throw Error.operationFailed("ldid entitlements failed")
        }

        defer { native_bridge_free_string(ptr) }
        let result = String(cString: ptr)
        print("[AltSign] LdidBridge.entitlements parsed successfully. Length: \(result.count) chars")
        return result
    }

    public static func requirements(at url: URL) throws -> String {
        let path = url.path
        print("[AltSign] LdidBridge.requirements(at: \(path)) started")
        guard !path.isEmpty else {
            print("[AltSign] LdidBridge.requirements failed: path is empty")
            throw Error.invalidPath
        }

        guard let ptr = path.withCString({ native_bridge_ldid_requirements($0) }) else {
            print("[AltSign] LdidBridge.requirements failed: native operation failed")
            throw Error.operationFailed("ldid requirements failed")
        }

        defer { native_bridge_free_string(ptr) }
        let result = String(cString: ptr)
        print("[AltSign] LdidBridge.requirements parsed successfully. Length: \(result.count) chars")
        return result
    }

    // MARK: Signing API

    public static func sign(
        appPath: String,
        keyData: Data,
        entitlementProvider: @escaping (String) -> String,
        progress: @escaping () -> Void
    ) throws {
        print("[AltSign] LdidBridge.sign started for appPath: \(appPath), keyData: \(keyData.count) bytes")

        guard !appPath.isEmpty else {
            print("[AltSign] LdidBridge.sign failed: appPath is empty")
            throw Error.invalidPath
        }

        // install callbacks
        _LdidCallbackStorage.entitlementProvider = { path in
            print("[AltSign] LdidBridge.sign entitlement trampoline callback for path: \(path)")
            return entitlementProvider(path)
        }
        _LdidCallbackStorage.progress = {
            print("[AltSign] LdidBridge.sign progress trampoline callback triggered")
            progress()
        }

        defer {
            _LdidCallbackStorage.entitlementProvider = nil
            _LdidCallbackStorage.progress = nil
        }

        var errorPtr: UnsafeMutablePointer<CChar>? = nil

        let ok = keyData.withUnsafeBytes { bytes in
            print("[AltSign] LdidBridge.sign calling native_bridge_ldid_sign")
            return native_bridge_ldid_sign(
                appPath,
                bytes.bindMemory(to: UInt8.self).baseAddress,
                Int32(keyData.count),
                ldid_entitlement_trampoline,
                ldid_progress_trampoline,
                &errorPtr
            )
        }

        if !ok {
            let message = errorPtr.map { String(cString: $0) } ?? "ldid sign failed"
            print("[AltSign] LdidBridge.sign native signing failed with error: \(message)")
            if let errorPtr { native_bridge_free_string(errorPtr) }
            throw Error.operationFailed(message)
        }

        print("[AltSign] LdidBridge.sign native signing completed successfully")
    }
}
