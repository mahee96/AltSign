//
//  CoreCryptoBridge.swift
//  AltSign
//

import Foundation
import NativeBridge

public enum CoreCryptoBridge {

    // MARK: - SRP

    public final class SRP {

        private let ctx: native_bridge_ccsrp_ctx

        public init?() {
            guard let c = native_bridge_ccsrp_client_new() else {
                return nil
            }
            self.ctx = c
        }

        deinit {
            native_bridge_ccsrp_client_free(ctx)
        }

        /// controlled escape hatch
        public var rawHandle: OpaquePointer {
            OpaquePointer(ctx)
        }

        public func exchangeSize() -> Int {
            Int(native_bridge_ccsrp_exchange_size(ctx))
        }

        public func startAuthentication() -> Data? {
            let size = exchangeSize()
            var A = Data(count: size)

            let result = A.withUnsafeMutableBytes {
                native_bridge_ccsrp_client_start_authentication(
                    ctx,
                    $0.baseAddress,
                    nil
                )
            }

            return result == 0 ? A : nil
        }

        public func processChallenge(
            username: String,
            password: String,
            salt: Data,
            serverPublicKey: Data
        ) -> Data? {

            let size =
                Int(native_bridge_ccsrp_get_session_key_length(ctx))

            var M1 = Data(count: size)

            let result = M1.withUnsafeMutableBytes { _ in
                salt.withUnsafeBytes { saltBytes in
                    serverPublicKey.withUnsafeBytes { bBytes in

                        native_bridge_ccsrp_client_process_challenge(
                            ctx,
                            saltBytes.baseAddress,
                            salt.count,
                            bBytes.baseAddress,
                            serverPublicKey.count,
                            username,
                            password
                        )
                    }
                }
            }

            return result == 0 ? M1 : nil
        }

        public func verifyServerProof(_ proof: Data) -> Bool {
            proof.withUnsafeBytes {
                native_bridge_ccsrp_client_verify_session(
                    ctx,
                    $0.baseAddress
                ) != 0
            }
        }

        public func sessionKey() -> Data? {

            guard let ptr =
                native_bridge_ccsrp_get_session_key(ctx)
            else { return nil }

            let len =
                Int(native_bridge_ccsrp_get_session_key_length(ctx))

            return Data(bytes: ptr, count: len)
        }
    }


    // MARK: - HMAC (SHA256)

    public static func hmacSHA256(
        key: Data,
        strings: [String]
    ) -> Data? {

        guard let di = native_bridge_ccsha256_di(),
              let ctx = native_bridge_cchmac_create(di)
        else { return nil }

        defer { native_bridge_cchmac_free(ctx) }

        key.withUnsafeBytes {
            native_bridge_cchmac_init(
                ctx,
                di,
                $0.baseAddress,
                key.count
            )
        }

        for s in strings {
            s.withCString {
                native_bridge_cchmac_update(
                    ctx,
                    di,
                    $0,
                    strlen($0)
                )
            }
        }

        var out = Data(count: 32)

        out.withUnsafeMutableBytes {
            native_bridge_cchmac_final(
                ctx,
                di,
                $0.baseAddress
            )
        }

        return out
    }


    // MARK: - PBKDF2

    public static func pbkdf2(
        digestInfo: UnsafeRawPointer,
        password: Data,
        salt: Data,
        rounds: Int,
        outputLength: Int
    ) -> Data? {

        var out = Data(count: outputLength)

        let result = out.withUnsafeMutableBytes { outBytes in
            password.withUnsafeBytes { pwdBytes in
                salt.withUnsafeBytes { saltBytes in

                    native_bridge_ccpbkdf2_hmac(
                        digestInfo,
                        pwdBytes.baseAddress?
                            .assumingMemoryBound(to: CChar.self),
                        password.count,
                        saltBytes.baseAddress,
                        salt.count,
                        UInt32(rounds),
                        outBytes.baseAddress,
                        outputLength
                    )
                }
            }
        }

        return result == 0 ? out : nil
    }
    
    
    // MARK: - Digest (SHA256)

    public static func sha256(_ data: Data) -> Data? {

        var out = Data(count: 32)

        let result = out.withUnsafeMutableBytes { outBytes in
            data.withUnsafeBytes { inBytes in
                native_bridge_ccdigest_sha256(
                    inBytes.baseAddress,
                    data.count,
                    outBytes.baseAddress
                )
            }
        }

        return result == 0 ? out : nil
    }
    
    
    public static func pbkdf2SHA256(
        password: Data,
        salt: Data,
        rounds: Int,
        outputLength: Int
    ) -> Data? {

        guard let di = native_bridge_ccsha256_di() else {
            return nil
        }

        return pbkdf2(
            digestInfo: di,
            password: password,
            salt: salt,
            rounds: rounds,
            outputLength: outputLength
        )
    }
    
    // MARK: - AES CBC

    public static func aesCBCDecrypt(
        key: Data,
        iv: Data,
        ciphertext: Data
    ) -> Data? {

        var out = Data(count: ciphertext.count)
        var outLen = 0

        let result = out.withUnsafeMutableBytes { outBytes in
            ciphertext.withUnsafeBytes { inBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in

                        native_bridge_aes_cbc_pkcs7_decrypt(
                            keyBytes.baseAddress,
                            key.count,
                            ivBytes.baseAddress,
                            inBytes.baseAddress,
                            ciphertext.count,
                            outBytes.baseAddress,
                            &outLen
                        )
                    }
                }
            }
        }

        guard result == 0 else { return nil }
        return out.prefix(outLen)
    }
    
    // MARK: - AES GCM

    public static func aesGCMDecrypt(
        key: Data,
        nonce: Data,
        aad: Data,
        ciphertext: Data,
        tag: Data
    ) -> Data? {

        var out = Data(count: ciphertext.count)

        let result = out.withUnsafeMutableBytes { outBytes in
            ciphertext.withUnsafeBytes { ctBytes in
                key.withUnsafeBytes { keyBytes in
                    nonce.withUnsafeBytes { nonceBytes in
                        aad.withUnsafeBytes { aadBytes in
                            tag.withUnsafeBytes { tagBytes in

                                native_bridge_aes_gcm_decrypt(
                                    keyBytes.baseAddress,
                                    key.count,
                                    nonceBytes.baseAddress,
                                    nonce.count,
                                    aadBytes.baseAddress,
                                    aad.count,
                                    ctBytes.baseAddress,
                                    ciphertext.count,
                                    tagBytes.baseAddress,
                                    tag.count,
                                    outBytes.baseAddress
                                )
                            }
                        }
                    }
                }
            }
        }

        return result == 0 ? out : nil
    }
}
