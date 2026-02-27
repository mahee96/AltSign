#include "native_bridge_ldid.h"
#include "alt_ldid.hpp"

#include <string>
#include <vector>
#include <cstring>
#include <cstdlib>
#include <fstream>

using namespace ldid;

/* --------------------------------------------------------- */
/* internal adapters                                         */
/* --------------------------------------------------------- */

static const char *(*g_entitlement_cb)(const char *) = nullptr;
static void (*g_progress_cb)(void) = nullptr;

static std::string entitlement_adapter(std::string path)
{
    if (!g_entitlement_cb) return "";

    const char *res = g_entitlement_cb(path.c_str());
    return res ? std::string(res) : "";
}

struct ProgressAdapter : ldid::Progress {
    void operator()(const std::string &) const override {
        if (g_progress_cb) g_progress_cb();
    }

    void operator()(double) const override {
        if (g_progress_cb) g_progress_cb();
    }
};

/* --------------------------------------------------------- */
/* helpers                                                   */
/* --------------------------------------------------------- */

static std::string readFile(const char *path)
{
    std::ifstream f(path, std::ios::binary);
    if (!f) throw std::runtime_error("failed to open input");

    return std::string(
        (std::istreambuf_iterator<char>(f)),
        std::istreambuf_iterator<char>()
    );
}

/* --------------------------------------------------------- */
/* C ABI                                                     */
/* --------------------------------------------------------- */

extern "C" {

char *native_bridge_ldid_entitlements(const char *path)
{
    if (!path) return nullptr;

    std::string value = Entitlements(path);
    if (value.empty()) return nullptr;

    return strdup(value.c_str());
}

char *native_bridge_ldid_requirements(const char *path)
{
    if (!path) return nullptr;

    std::string value = Requirements(path);
    if (value.empty()) return nullptr;

    return strdup(value.c_str());
}

bool native_bridge_ldid_sign(
    const char *appPath,
    const unsigned char *p12Bytes,
    int p12Length,
    const char *(*entitlement_callback)(const char *),
    void (*progress_callback)(void),
    char **errorMessage
)
{
    try {
        g_entitlement_cb = entitlement_callback;
        g_progress_cb = progress_callback;

        /* ---- read binary ---- */
        std::string input = readFile(appPath);

        /* ---- output overwrite ---- */
        std::filebuf out;
        if (!out.open(appPath, std::ios::out | std::ios::binary | std::ios::trunc))
            throw std::runtime_error("failed to open output");

        /* ---- key as string (ldid expects PKCS12 blob) ---- */
        std::string key(
            reinterpret_cast<const char *>(p12Bytes),
            p12Length
        );

        /* ---- entitlements ---- */
        std::string entitlements =
            entitlement_adapter(std::string(appPath));

        ldid::Slots slots;
        ProgressAdapter progress;

        /* ---- REAL API CALL ---- */
        ldid::Sign(
            input.data(),
            input.size(),
            out,
            std::string(appPath),   // identifier (ldid CLI uses filename)
            entitlements,
            false,
            "",
            key,
            slots,
            0,
            false,
            progress
        );

        return true;
    }
    catch (const std::exception &e) {
        if (errorMessage)
            *errorMessage = strdup(e.what());
        return false;
    }
}

} // extern "C"
