//
//  ZipBridge.swift
//  AltSign
//

import Foundation
import NativeBridge

public enum ZipBridge {

    // MARK: - Archive Reader

    public final class Archive {

        private let handle: native_bridge_unzFile

        private init(_ handle: native_bridge_unzFile) {
            self.handle = handle
        }

        deinit {
            native_bridge_unzClose(handle)
        }

        // MARK: Open

        public static func open(at url: URL) throws -> Archive {
            guard let h = url.path.withCString({
                native_bridge_unzOpen($0)
            }) else {
                throw ZipError.corruptArchive(url)
            }
            return Archive(h)
        }

        // MARK: Navigation

        public func goToFirstFile() throws {
            guard native_bridge_unzGoToFirstFile(handle) == 0 else {
                throw ZipError.readFailed(.init(fileURLWithPath: ""))
            }
        }

        public func goToNextFile() -> Bool {
            native_bridge_unzGoToNextFile(handle) == 0
        }

        // MARK: File Info

        public func currentFilename() throws -> String {

            var info = [UInt8](repeating: 0, count: 256)
            var name = [CChar](repeating: 0, count: 1024)

            let r = native_bridge_unzGetCurrentFileInfo(
                handle,
                &info,
                &name,
                1024
            )

            guard r == 0 else {
                throw ZipError.readFailed(.init(fileURLWithPath: ""))
            }

            return String(cString: name)
        }

        // MARK: Reading

        public func readCurrentFile() throws -> Data {

            guard native_bridge_unzOpenCurrentFile(handle) == 0 else {
                throw ZipError.readFailed(.init(fileURLWithPath: ""))
            }

            defer {
                native_bridge_unzCloseCurrentFile(handle)
            }

            var result = Data()
            var buffer = [UInt8](repeating: 0, count: 32_768)

            while true {

                let read = native_bridge_unzReadCurrentFile(
                    handle,
                    &buffer,
                    UInt32(buffer.count)
                )

                if read < 0 {
                    throw ZipError.readFailed(.init(fileURLWithPath: ""))
                }

                if read == 0 { break }

                result.append(buffer, count: Int(read))
            }

            return result
        }
    }

    // MARK: - Archive Writer

    public final class Writer {

        private let handle: native_bridge_zipFile

        private init(_ handle: native_bridge_zipFile) {
            self.handle = handle
        }

        deinit {
            native_bridge_zipClose(handle)
        }

        public static func create(at url: URL) throws -> Writer {
            guard let h = url.path.withCString({
                native_bridge_zipOpen($0)
            }) else {
                throw ZipError.writeFailed(url)
            }
            return Writer(h)
        }

        public func writeFile(path: String, data: Data?) throws {

            let openOK = path.withCString {
                native_bridge_zipOpenNewFileInZip(handle, $0)
            } == 0

            guard openOK else {
                throw ZipError.writeFailed(.init(fileURLWithPath: path))
            }

            defer {
                native_bridge_zipCloseFileInZip(handle)
            }

            guard let data else { return }

            let ok = data.withUnsafeBytes {
                native_bridge_zipWriteInFileInZip(
                    handle,
                    $0.baseAddress,
                    UInt32(data.count)
                )
            } == 0

            guard ok else {
                throw ZipError.writeFailed(.init(fileURLWithPath: path))
            }
        }
    }
}

public enum ZipError: Error {

    case fileNotFound(URL)
    case corruptArchive(URL)
    case readFailed(URL)
    case writeFailed(URL)
    case missingAppBundle(URL)
}

// MARK: - LocalizedError

extension ZipError: LocalizedError {

    public var errorDescription: String? {
        switch self {

        case .fileNotFound(let url):
            return "File not found: \(url.lastPathComponent)"

        case .corruptArchive(let url):
            return "Archive appears to be corrupt: \(url.lastPathComponent)"

        case .readFailed(let url):
            return "Failed to read archive: \(url.lastPathComponent)"

        case .writeFailed(let url):
            return "Failed to write archive: \(url.lastPathComponent)"

        case .missingAppBundle(let url):
            return "No .app bundle found inside \(url.lastPathComponent)"
        }
    }
}
