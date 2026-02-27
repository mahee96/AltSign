//
//  native_bridge_ldid.h
//  AltSign
//
//  Created by Magesh K on 25/02/26.
//


#pragma once
#include "native_bridge_common.h"

#ifdef __cplusplus
extern "C" {
#endif

char *native_bridge_ldid_entitlements(const char *path);
char *native_bridge_ldid_requirements(const char *path);

bool native_bridge_ldid_sign(
    const char *appPath,
    const unsigned char *p12Bytes,
    int p12Length,
    const char *(*entitlement_callback)(const char *relativePath),
    void (*progress_callback)(void),
    char **errorMessage
);

#ifdef __cplusplus
}
#endif
