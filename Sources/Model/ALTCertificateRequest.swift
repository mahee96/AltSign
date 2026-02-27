//
//  ALTCertificateRequest.swift
//  AltSign
//

import Foundation
import SwiftBridge


public final class ALTCertificateRequest: NSObject {

    // MARK: Properties

    public let data: Data
    public let privateKey: Data

    // MARK: Init

    private init(data: Data, privateKey: Data) {
        self.data = data
        self.privateKey = privateKey
        super.init()
    }

    // MARK: Factory (matches ObjC API)


    public static func makeRequest() -> ALTCertificateRequest? {

        let subject = OpenSSLBridge.CSRSubject(
            country: "US",
            state: "CA",
            locality: "Los Angeles",
            organization: "AltSign",
            commonName: "AltSign"
        )

        guard let result = try? OpenSSLBridge.generateCSR(subject: subject)
        else { return nil }

        return ALTCertificateRequest(
            data: result.csr,
            privateKey: result.privateKey
        )
    }
}

// MARK: - OpenSSL CSR Generation
//
//private extension ALTCertificateRequest {
//
//    static func generateRequest(
//        outputRequest: inout Data?,
//        privateKey: inout Data?
//    ) {
//
//        var bignum: UnsafeMutablePointer<BIGNUM>?
//        var rsa: UnsafeMutablePointer<RSA>?
//        var request: UnsafeMutablePointer<X509_REQ>?
//        var publicKey: UnsafeMutablePointer<EVP_PKEY>?
//
//        var csrBIO: UnsafeMutablePointer<BIO>?
//        var privateBIO: UnsafeMutablePointer<BIO>?
//
//        func finish() {
//            if let publicKey {
//                EVP_PKEY_free(publicKey)   // frees RSA too
//            } else if let rsa {
//                RSA_free(rsa)
//            }
//
//            if let bignum { BN_free(bignum) }
//            if let request { X509_REQ_free(request) }
//
//            if let csrBIO { BIO_free_all(csrBIO) }
//            if let privateBIO { BIO_free_all(privateBIO) }
//        }
//
//        // MARK: RSA Key
//
//        bignum = BN_new()
//        guard BN_set_word(bignum, RSA_F4) == 1 else {
//            finish(); return
//        }
//
//        rsa = RSA_new()
//        guard RSA_generate_key_ex(rsa, 2048, bignum, nil) == 1 else {
//            finish(); return
//        }
//
//        // MARK: CSR
//
//        request = X509_REQ_new()
//        guard X509_REQ_set_version(request, 1) == 1 else {
//            finish(); return
//        }
//
//        let subject = X509_REQ_get_subject_name(request)
//
//        func add(_ key: String, _ value: String) {
//            value.withCString {
//                X509_NAME_add_entry_by_txt(
//                    subject,
//                    key,
//                    MBSTRING_ASC,
//                    UnsafePointer<UInt8>($0),
//                    -1, -1, 0
//                )
//            }
//        }
//
//        add("C", "US")
//        add("ST", "CA")
//        add("L", "Los Angeles")
//        add("O", "AltSign")
//        add("CN", "AltSign")
//
//        publicKey = EVP_PKEY_new()
//        EVP_PKEY_assign_RSA(publicKey, rsa)
//
//        guard X509_REQ_set_pubkey(request, publicKey) == 1 else {
//            finish(); return
//        }
//
//        guard X509_REQ_sign(request, publicKey, EVP_sha1()) > 0 else {
//            finish(); return
//        }
//
//        // MARK: Output CSR
//
//        csrBIO = BIO_new(BIO_s_mem())
//        guard PEM_write_bio_X509_REQ(csrBIO, request) == 1 else {
//            finish(); return
//        }
//
//        privateBIO = BIO_new(BIO_s_mem())
//        guard PEM_write_bio_RSAPrivateKey(
//            privateBIO,
//            rsa,
//            nil,
//            nil,
//            0,
//            nil,
//            nil
//        ) == 1 else {
//            finish(); return
//        }
//
//        var csrPtr: UnsafeMutablePointer<CChar>?
//        let csrLen = BIO_get_mem_data(csrBIO, &csrPtr)
//        outputRequest = Data(bytes: csrPtr!, count: csrLen)
//
//        var keyPtr: UnsafeMutablePointer<CChar>?
//        let keyLen = BIO_get_mem_data(privateBIO, &keyPtr)
//        privateKey = Data(bytes: keyPtr!, count: keyLen)
//
//        finish()
//    }
//}
