// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "AltSign",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
		// MARK: - AltSign
        .library(
            name: "AltSign",
            targets: ["AltSign"]
        ),

        .library(
            name: "AltSign-Static",
            type: .static,
            targets: ["AltSign"]
        ),

        .library(
            name: "AltSign-Dynamic",
            type: .dynamic,
            targets: ["AltSign"]
        ),

		// MARK: - CoreCrypto
		.library(
			name: "CoreCrypto",
			targets: ["CoreCrypto", "CCoreCrypto"]
		),

		.library(
			name: "CoreCrypto-Static",
			type: .static,
			targets: ["CoreCrypto", "CCoreCrypto"]
		),

		.library(
			name: "CoreCrypto-Dynamic",
			type: .dynamic,
			targets: ["CoreCrypto", "CCoreCrypto"]
		),

		// MARK: - CCoreCrypto
		.library(
			name: "CCoreCrypto",
			targets: ["CCoreCrypto"]
		),

		.library(
			name: "CCoreCrypto-Static",
			type: .static,
			targets: ["CCoreCrypto"]
		),

		.library(
			name: "CCoreCrypto-Dynamic",
			type: .dynamic,
			targets: ["CCoreCrypto"]
		)
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/OpenSSL.git", .upToNextMinor(from: "1.1.180"))
    ],
    targets: [
        // MARK: - AltSign

        .target(
            name: "AltSign",
            dependencies: [
                "CAltSign"
            ],
            cSettings: [
                .headerSearchPath("../minizip/include"),
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1")
            ]
        ),

		.testTarget(
			name: "AltSignTests",
			dependencies: ["AltSign"]
		),

        .target(
            name: "CAltSign",
            dependencies: [
                "CoreCrypto",
                "ldid",
                "minizip"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include/"),
                .headerSearchPath("include/AltSign"),
                .headerSearchPath("Capabilities"),
                .headerSearchPath("../ldid"),
                .headerSearchPath("../ldid/include"),
                .headerSearchPath("../minizip/include"),
                .headerSearchPath("../ldid/libplist/include"),
                .headerSearchPath("../ldid"),
                .define("unix", to: "1"),
                .unsafeFlags([
                    "-w"
                ])
            ],
            cxxSettings: [
                .headerSearchPath("include/"),
                .headerSearchPath("include/AltSign"),
                .headerSearchPath("Capabilities"),
                .headerSearchPath("../ldid"),
                .headerSearchPath("../ldid/include"),
                .headerSearchPath("../minizip/include"),
                .headerSearchPath("../ldid/libplist/include"),
                .headerSearchPath("../ldid"),
                .define("unix", to: "1"),
                .unsafeFlags([
                    "-w"
                ])
            ],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("Security")
            ]
        ),

        // MARK: - ldid

        .target(
            name: "ldid-core",
            dependencies: [
                "OpenSSL"
            ],
            exclude: [
                "ldid.hpp",
                "ldid.cpp",
                "version.sh",
                "COPYING",
                "control.sh",
                "control",
                "ios.sh",
                "make.sh",
                "deb.sh",
                "plist.sh",
                "libplist/include",
                "libplist/include/Makefile.am",
                "libplist/fuzz",
                "libplist/cython",
                "libplist/m4",
                "libplist/test",
                "libplist/tools",
                "libplist/AUTHORS",
                "libplist/autogen.sh",
                "libplist/configure.ac",
                "libplist/COPYING",
                "libplist/COPYING.LESSER",
                "libplist/doxygen.cfg.in",
                "libplist/Makefile.am",
                "libplist/NEWS",
                "libplist/README.md",
                "libplist/src/Makefile.am",
                "libplist/src/libplist++.pc.in",
                "libplist/src/libplist.pc.in",
                "libplist/libcnary/cnary.c",
                "libplist/libcnary/COPYING",
                "libplist/libcnary/Makefile.am",
                "libplist/libcnary/README"
            ],
            sources: [
                "lookup2.c",
                "libplist/src",
                "libplist/libcnary"
            ],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("libplist/include"),
                .headerSearchPath("libplist/src"),
                .headerSearchPath("libplist/libcnary/include"),
//                .headerSearchPath("../OpenSSL/ios/include"),

                .unsafeFlags(["-w"])
            ],
            cxxSettings: [
                .unsafeFlags(["-w"])
            ]
        ),

        .target(
            name: "ldid",
            dependencies: ["ldid-core"],
            sources: [
                "alt_ldid.cpp"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("../../Dependencies/ldid"),
                .headerSearchPath("../../Dependencies/ldid/libplist/include"),
                .headerSearchPath("../../Dependencies/ldid/libplist/src"),
                .headerSearchPath("../../Dependencies/ldid/libplist/libcnary/include"),
//                .headerSearchPath("../../Dependencies/OpenSSL/ios/include"),
            ],
            cxxSettings: [
                .unsafeFlags(["-w"])
            ]
        ),

        // MARK: - CoreCrypto

        .target(
            name: "CCoreCrypto",
            exclude: [
                "Sources/CoreCryptoMacros.swift"
            ],
            cSettings: [
                .headerSearchPath("include/corecrypto"),
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1")
            ]
        ),

        .target(
            name: "CoreCrypto",
            dependencies: ["CCoreCrypto"],
            exclude: [
                "Sources/ccsrp.m"
            ],
            cSettings: [
                // Recursive wildcard paths no longer work as of Xcode 16 :(
                // .headerSearchPath("AltSign/**"),
                .headerSearchPath("AltSign/include/AltSign"),
                .headerSearchPath("Dependencies/minizip"),
                .headerSearchPath("AltSign/Capabilities"),
                .headerSearchPath("Dependencies/OpenSSL/ios/include"),
                .headerSearchPath("Dependencies/ldid/libplist/include"),
                .headerSearchPath("Dependencies/ldid"),
                .define("unix=1")
            ],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("Security")
            ]
        ),

        // MARK: - minizip

        .target(
            name: "minizip",
            sources: [
                "minizip/zip.c",
                "minizip/unzip.c",
                "minizip/ioapi.c"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-w"
                ])
                .headerSearchPath("Dependencies/minizip"),
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1"),
            ],
            swiftSettings: [
                .define("MARKETPLACE")
            ]
        )
    ],

    cLanguageStandard: CLanguageStandard.gnu11,
    cxxLanguageStandard: .cxx14
)
