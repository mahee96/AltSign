// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "AltSign",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],

    products: [
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
        .library(
            name: "OpenSSL",
            targets: ["OpenSSL"]
        )
    ],


    targets: [
        .binaryTarget(
            name: "OpenSSL",
            path: "Dependencies/OpenSSL.xcframework"
        ),

        // ─────────────────────────
        // C / C++ bridge
        // ─────────────────────────
        .target(
            name: "NativeBridge",
            dependencies: [
                "OpenSSL",
            ],
            path: ".",
            sources: [
                "NativeBridge/Sources",
                "ldid/alt_ldid.cpp",
                
                "Dependencies/minizip/ioapi.c",
                "Dependencies/minizip/mztools.c",
                "Dependencies/minizip/unzip.c",
                "Dependencies/minizip/zip.c",

                "Dependencies/ldid/lookup2.c",
                "Dependencies/ldid/libplist/src/base64.c",
                "Dependencies/ldid/libplist/src/bplist.c",
                "Dependencies/ldid/libplist/src/bytearray.c",
                "Dependencies/ldid/libplist/src/common.c",
                "Dependencies/ldid/libplist/src/hashtable.c",
                "Dependencies/ldid/libplist/src/jplist.c",
                "Dependencies/ldid/libplist/src/jsmn.c",
                "Dependencies/ldid/libplist/src/oplist.c",
                "Dependencies/ldid/libplist/src/out-default.c",
                "Dependencies/ldid/libplist/src/out-limd.c",
                "Dependencies/ldid/libplist/src/out-plutil.c",
                "Dependencies/ldid/libplist/src/plist.c",
                "Dependencies/ldid/libplist/src/ptrarray.c",
                "Dependencies/ldid/libplist/src/time64.c",
                "Dependencies/ldid/libplist/src/xplist.c",
                "Dependencies/ldid/libplist/libcnary/node.c",
                "Dependencies/ldid/libplist/libcnary/node_list.c",

                "Dependencies/corecrypto/Sources/ccsrp.m"
            ],

            publicHeadersPath: "NativeBridge/include",

            cSettings: [
                .headerSearchPath("Dependencies/minizip"),

                .headerSearchPath("ldid"),
                .headerSearchPath("Dependencies/ldid"),
                .headerSearchPath("Dependencies/ldid/libplist/include"),
                .headerSearchPath("Dependencies/ldid/libplist/src"),
                .headerSearchPath("Dependencies/ldid/libplist/libcnary/include"),

                .headerSearchPath("Dependencies/corecrypto/include"),
                .headerSearchPath("Dependencies/corecrypto/include/corecrypto"),

                .define("unix", to: "1"),
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION", to: "1"),
                .define("NOCRYPT"),
                .define("NOUNCRYPT"),

                .unsafeFlags(["-w"])
            ],

            cxxSettings: [
                .headerSearchPath("NativeBridge/include"),
                .headerSearchPath("ldid"),
                .headerSearchPath("Dependencies/corecrypto/include"),
                .unsafeFlags(["-w"])
            ],

            linkerSettings: [
                .linkedLibrary("z"),
                .linkedFramework("Security"),
                // .linkedFramework("CommonCrypto"),
                // .linkedFramework("OpenSSL")
            ]
        ),

        // ─────────────────────────
        // Swift-safe bridge
        // ─────────────────────────
        .target(
            name: "SwiftBridge",
            dependencies: ["NativeBridge"],
            path: "SwiftBridge",
            sources: [ "." ]
        ),
//
//        // ─────────────────────────
//        // Main Swift target
//        // ─────────────────────────
        .target(
            name: "AltSign",
            dependencies: ["SwiftBridge"],
            path: "Sources"
        )
    ],

    cLanguageStandard: .gnu11,
    cxxLanguageStandard: .cxx14
)
