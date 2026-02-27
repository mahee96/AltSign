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
        guard !path.isEmpty else { throw Error.invalidPath }

        guard let ptr = path.withCString({ native_bridge_ldid_entitlements($0) }) else {
            throw Error.operationFailed("ldid entitlements failed")
        }

        defer { native_bridge_free_string(ptr) }
        return String(cString: ptr)
    }

    public static func requirements(at url: URL) throws -> String {
        let path = url.path
        guard !path.isEmpty else { throw Error.invalidPath }

        guard let ptr = path.withCString({ native_bridge_ldid_requirements($0) }) else {
            throw Error.operationFailed("ldid requirements failed")
        }

        defer { native_bridge_free_string(ptr) }
        return String(cString: ptr)
    }

    // MARK: Signing API

    public static func sign(
        appPath: String,
        keyData: Data,
        entitlementProvider: @escaping (String) -> String,
        progress: @escaping () -> Void
    ) throws {

        guard !appPath.isEmpty else {
            throw Error.invalidPath
        }

        // install callbacks
        _LdidCallbackStorage.entitlementProvider = entitlementProvider
        _LdidCallbackStorage.progress = progress

        defer {
            _LdidCallbackStorage.entitlementProvider = nil
            _LdidCallbackStorage.progress = nil
        }

        var errorPtr: UnsafeMutablePointer<CChar>? = nil

        let ok = keyData.withUnsafeBytes { bytes in
            native_bridge_ldid_sign(
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
            if let errorPtr { native_bridge_free_string(errorPtr) }
            throw Error.operationFailed(message)
        }
    }
}
