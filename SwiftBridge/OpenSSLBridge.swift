import Foundation
import NativeBridge


public enum OpenSSLBridge {

    // MARK: CSR Subject

    public struct CSRSubject {
        public let country: String
        public let state: String
        public let locality: String
        public let organization: String
        public let commonName: String

        public init(
            country: String,
            state: String,
            locality: String,
            organization: String,
            commonName: String
        ) {
            self.country = country
            self.state = state
            self.locality = locality
            self.organization = organization
            self.commonName = commonName
        }
    }

    public enum Error: Swift.Error {
        case operationFailed(String)
    }

    // MARK: CSR Generation

    public static func generateCSR(
        subject: CSRSubject
    ) throws -> (csr: Data, privateKey: Data) {

        var csrPtr: UnsafeMutablePointer<UInt8>?
        var csrLen: Int32 = 0

        var keyPtr: UnsafeMutablePointer<UInt8>?
        var keyLen: Int32 = 0

        var errorPtr: UnsafeMutablePointer<CChar>?

        let ok: Int32 =
        subject.country.withCString { c in
            subject.state.withCString { st in
                subject.locality.withCString { l in
                    subject.organization.withCString { o in
                        subject.commonName.withCString { cn in

                            native_bridge_generate_csr(
                                c,
                                st,
                                l,
                                o,
                                cn,
                                &csrPtr,
                                &csrLen,
                                &keyPtr,
                                &keyLen,
                                &errorPtr
                            )
                        }
                    }
                }
            }
        }

        guard ok != 0 else {
            let message =
                errorPtr.map { String(cString: $0) }
                ?? "CSR generation failed"

            if let errorPtr { native_bridge_free_string(errorPtr) }
            throw Error.operationFailed(message)
        }

        guard let csrPtr, let keyPtr else {
            throw Error.operationFailed("CSR output missing")
        }

        let csr = Data(bytes: csrPtr, count: Int(csrLen))
        let key = Data(bytes: keyPtr, count: Int(keyLen))

        native_bridge_free(csrPtr)
        native_bridge_free(keyPtr)

        return (csr, key)
    }


    // MARK: PKCS12 Extract

    public static func extractPKCS12(
        _ data: Data,
        password: String?
    ) -> (cert: Data, key: Data)? {

        var certPtr: UnsafeMutablePointer<UInt8>?
        var certLen: Int32 = 0

        var keyPtr: UnsafeMutablePointer<UInt8>?
        var keyLen: Int32 = 0

        let ok: Int32 = data.withUnsafeBytes { buf in
            native_bridge_pkcs12_extract(
                buf.bindMemory(to: UInt8.self).baseAddress,
                Int32(data.count),
                password,
                &certPtr,
                &certLen,
                &keyPtr,
                &keyLen
            )
        }

        guard ok != 0,
              let certPtr,
              let keyPtr else { return nil }

        let cert = Data(bytes: certPtr, count: Int(certLen))
        let key  = Data(bytes: keyPtr,  count: Int(keyLen))

        native_bridge_free(certPtr)
        native_bridge_free(keyPtr)

        return (cert, key)
    }


    // MARK: Certificate Parse

    public static func parseCertificate(
        _ data: Data
    ) -> (name: String, serial: String)? {

        var namePtr: UnsafeMutablePointer<CChar>?
        var serialPtr: UnsafeMutablePointer<CChar>?

        let ok: Int32 = data.withUnsafeBytes { buf in
            native_bridge_x509_parse(
                buf.bindMemory(to: UInt8.self).baseAddress,
                Int32(data.count),
                &namePtr,
                &serialPtr
            )
        }

        guard ok != 0,
              let namePtr,
              let serialPtr else { return nil }

        let name = String(cString: namePtr)
        let serial = String(cString: serialPtr)

        native_bridge_free(namePtr)
        native_bridge_free(serialPtr)

        return (name, serial)
    }


    // MARK: PKCS12 Create

    public static func createPKCS12(
        cert: Data,
        key: Data,
        password: String
    ) -> Data? {

        var outPtr: UnsafeMutablePointer<UInt8>?
        var outLen: Int32 = 0

        let ok: Int32 = cert.withUnsafeBytes { cbuf in
            key.withUnsafeBytes { kbuf in
                native_bridge_pkcs12_create(
                    cbuf.bindMemory(to: UInt8.self).baseAddress,
                    Int32(cert.count),
                    kbuf.bindMemory(to: UInt8.self).baseAddress,
                    Int32(key.count),
                    password,
                    &outPtr,
                    &outLen
                )
            }
        }

        guard ok != 0, let outPtr else { return nil }

        let result = Data(bytes: outPtr, count: Int(outLen))
        native_bridge_free(outPtr)

        return result
    }
}
