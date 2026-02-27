//
//  Data+Encryption.swift
//  AltSign
//

import Foundation
import NativeBridge

enum EncryptionError: Error {
    case decryptFailed
}

extension Data {

    func aesCBCDecrypt(
        key: Data,
        iv: Data
    ) throws -> Data {

        var output = Data(count: self.count)
        var outputLength: size_t = 0

        let result = self.withUnsafeBytes { inputPtr in
            key.withUnsafeBytes { keyPtr in
                iv.withUnsafeBytes { ivPtr in
                    output.withUnsafeMutableBytes { outPtr in

                        native_bridge_aes_cbc_pkcs7_decrypt(
                            keyPtr.baseAddress,
                            key.count,
                            ivPtr.baseAddress,
                            inputPtr.baseAddress,
                            self.count,
                            outPtr.baseAddress,
                            &outputLength
                        )
                    }
                }
            }
        }

        guard result == 0 else {
            throw EncryptionError.decryptFailed
        }

        output.removeSubrange(outputLength..<output.count)
        return output
    }

    // MARK: - AES GCM

    func aesGCMDecrypt(
        key: Data,
        nonce: Data,
        aad: Data?,
        tag: Data
    ) throws -> Data {

        var plaintext = Data(count: self.count)

        let rc = self.withUnsafeBytes { cipherPtr in
            key.withUnsafeBytes { keyPtr in
                nonce.withUnsafeBytes { noncePtr in
                    tag.withUnsafeBytes { tagPtr in
                        plaintext.withUnsafeMutableBytes { plainPtr in

                            native_bridge_aes_gcm_decrypt(
                                keyPtr.baseAddress,
                                key.count,
                                noncePtr.baseAddress,
                                nonce.count,
                                aad?.withUnsafeBytes { $0.baseAddress },
                                aad?.count ?? 0,
                                cipherPtr.baseAddress,
                                self.count,
                                tagPtr.baseAddress,
                                tag.count,
                                plainPtr.baseAddress
                            )
                        }
                    }
                }
            }
        }

        guard rc == 0 else {
            throw EncryptionError.decryptFailed
        }

        return plaintext
    }
}

// MARK: - AltSign compatibility (GSAContext helpers)

extension Data {

    func decryptedCBC(context: GSAContext) -> Data? {
        guard let key = context.sessionKey else { return nil }

        // AltSign format:
        // first 16 bytes = IV
        // remaining      = ciphertext
        guard self.count > 16 else { return nil }

        let iv = self.prefix(16)
        let ciphertext = self.dropFirst(16)

        return try? Data(ciphertext).aesCBCDecrypt(
            key: key,
            iv: iv
        )
    }

    func decryptedGCM(context: GSAContext) -> Data? {
        guard let key = context.sessionKey else { return nil }

        // AltSign GCM layout:
        // 0..<12   = nonce
        // 12..<(n-16) = ciphertext
        // last 16  = tag
        guard self.count > (12 + 16) else { return nil }

        let nonce = self.prefix(12)
        let tag = self.suffix(16)
        let ciphertext = self.dropFirst(12).dropLast(16)

        return try? Data(ciphertext).aesGCMDecrypt(
            key: key,
            nonce: nonce,
            aad: nil,
            tag: tag
        )
    }
}
