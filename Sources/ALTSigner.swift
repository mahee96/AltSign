//
//  ALTSigner.swift
//  AltSign
//

import Foundation
import SwiftBridge


public final class ALTSigner: NSObject {

    // MARK: Properties

    public var team: ALTTeam
    public var certificate: ALTCertificate

    // MARK: Init

    
    public init(team: ALTTeam, certificate: ALTCertificate) {
        self.team = team
        self.certificate = certificate
        super.init()
    }

    // MARK: Public API (IDENTICAL SIGNATURE)

    public func signApp(
        at appURL: URL,
        provisioningProfiles profiles: [ALTProvisioningProfile],
        completionHandler: @escaping (Bool, Error?) -> Void
    ) -> Progress {

        let progress = Progress(totalUnitCount: 1)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.performSigning(
                    appURL: appURL,
                    profiles: profiles,
                    progress: progress
                )

                completionHandler(true, nil)
            } catch {
                completionHandler(false, error)
            }
        }

        return progress
    }
}

// MARK: - Core Signing Logic

private extension ALTSigner {

    func performSigning(
        appURL: URL,
        profiles: [ALTProvisioningProfile],
        progress: Progress
    ) throws {

        guard let application = ALTApplication(fileURL: appURL) else {
            throw NSError(
                domain: AltSignErrorDomain,
                code: ALTError.invalidApp.rawValue
            )
        }

        func profile(for app: ALTApplication) -> ALTProvisioningProfile? {
            for profile in profiles
            where profile.bundleIdentifier == app.bundleIdentifier {
                return profile
            }
            return profiles.first
        }

        var entitlementsByURL: [URL: String] = [:]

        func prepare(_ app: ALTApplication) throws {

            guard let profile = profile(for: app) else {
                throw NSError(
                    domain: AltSignErrorDomain,
                    code: ALTError.missingProvisioningProfile.rawValue
                )
            }

            let profileURL =
                app.fileURL.appendingPathComponent("embedded.mobileprovision")

            try profile.data.write(to: profileURL)

            var filtered = profile.entitlements

            for (key, _) in profile.entitlements {
                if app.entitlements[key] == nil {

                    if key == ALTEntitlementApplicationIdentifier ||
                       key == ALTEntitlementTeamIdentifier ||
                       key == ALTEntitlementGetTaskAllow {
                        continue
                    }

                    filtered.removeValue(forKey: key)
                }
            }

            let plist = try PropertyListSerialization.data(
                fromPropertyList: filtered,
                format: .xml,
                options: 0
            )

            guard let string = String(data: plist, encoding: .utf8) else {
                throw NSError(
                    domain: AltSignErrorDomain,
                    code: ALTError.unknown.rawValue
                )
            }

            entitlementsByURL[
                app.fileURL.resolvingSymlinksInPath()
            ] = string
        }

        try prepare(application)

        for ext in application.appExtensions {
            try prepare(ext)
        }

        // ---- LDID SIGNING VIA NATIVE BRIDGE ----

        guard let keyData = certificate.p12Data() else {
            throw NSError(
                domain: AltSignErrorDomain,
                code: ALTError.unknown.rawValue
            )
        }
        
        try LdidBridge.sign(
            appPath: application.fileURL.path,
            keyData: keyData,
            entitlementProvider: { path in
                let url: URL

                if path.isEmpty {
                    url = application.fileURL
                } else {
                    url = application.fileURL
                        .appendingPathComponent(path)
                }

                return entitlementsByURL[
                    url.resolvingSymlinksInPath()
                ] ?? ""
            },
            progress: {
                progress.completedUnitCount += 1
            }
        )
    }
}
