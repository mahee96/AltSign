// native_bridge_openssl.h
#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

int native_bridge_pkcs12_extract(
    const uint8_t *p12_bytes,
    int32_t p12_len,
    const char *password,
    uint8_t **out_cert,
    int32_t *out_cert_len,
    uint8_t **out_key,
    int32_t *out_key_len
);

int native_bridge_x509_parse(
    const uint8_t *pem_bytes,
    int32_t pem_len,
    char **out_name,
    char **out_serial
);

int native_bridge_pkcs12_create(
    const uint8_t *cert_bytes,
    int32_t cert_len,
    const uint8_t *key_bytes,
    int32_t key_len,
    const char *password,
    uint8_t **out_p12,
    int32_t *out_p12_len
);

int native_bridge_generate_csr(
    const char *country,
    const char *state,
    const char *locality,
    const char *organization,
    const char *common_name,
    uint8_t **out_csr,
    int32_t *out_csr_len,
    uint8_t **out_key,
    int32_t *out_key_len,
    char **out_error
);

#ifdef __cplusplus
}
#endif
