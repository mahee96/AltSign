//
//  FileManager+Zip.swift
//  AltSign
//

import Foundation
import SwiftBridge

extension FileManager {

    // MARK: unzipArchive

    func unzipArchive(
        at archiveURL: URL,
        to directoryURL: URL,
        progress: Progress? = nil
    ) throws {

        let archive = try ZipBridge.Archive.open(at: archiveURL)
        try archive.goToFirstFile()

        repeat {

            let name = try archive.currentFilename()

            if name.hasPrefix("__MACOSX") {
                continue
            }

            let outputURL =
                directoryURL.appendingPathComponent(name)

            if name.hasSuffix("/") {

                try createDirectory(
                    at: outputURL,
                    withIntermediateDirectories: true
                )
                continue
            }

            try createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let data = try archive.readCurrentFile()

            createFile(atPath: outputURL.path, contents: data)

            progress?.completedUnitCount += Int64(data.count)

        } while archive.goToNextFile()
    }

    // MARK: unzipAppBundle

    func unzipAppBundle(
        at ipaURL: URL,
        to directoryURL: URL
    ) throws -> URL {

        try unzipArchive(at: ipaURL, to: directoryURL)

        let payload = directoryURL.appendingPathComponent("Payload")
        let contents = try contentsOfDirectory(atPath: payload.path)

        for file in contents where file.lowercased().hasSuffix(".app") {

            let appURL = payload.appendingPathComponent(file)
            let outputURL = directoryURL.appendingPathComponent(file)

            try moveItem(at: appURL, to: outputURL)
            try removeItem(at: payload)

            return outputURL
        }

        throw ZipError.missingAppBundle(ipaURL)
    }

    // MARK: zipAppBundle

    func zipAppBundle(at appBundleURL: URL) throws -> URL {

        let name = appBundleURL.deletingPathExtension().lastPathComponent

        let ipaURL = appBundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(name).ipa")

        if fileExists(atPath: ipaURL.path) {
            try removeItem(at: ipaURL)
        }

        let writer = try ZipBridge.Writer.create(at: ipaURL)

        let payloadRoot =
            URL(fileURLWithPath: "Payload", isDirectory: true)

        let bundleRoot =
            payloadRoot.appendingPathComponent(
                appBundleURL.lastPathComponent
            )

        let enumerator = self.enumerator(
            at: appBundleURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        )!

        for case let fileURL as URL in enumerator {

            var isDir: ObjCBool = false
            fileExists(atPath: fileURL.path, isDirectory: &isDir)

            let relative = fileURL.path
                .replacingOccurrences(of: appBundleURL.path + "/", with: "")

            let zipPath =
                bundleRoot.appendingPathComponent(relative).path +
                (isDir.boolValue ? "/" : "")

            let data = isDir.boolValue ? nil : try Data(contentsOf: fileURL)

            try writer.writeFile(path: zipPath, data: data)
        }

        return ipaURL
    }
}
