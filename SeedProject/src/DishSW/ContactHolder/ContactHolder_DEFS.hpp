#pragma once

#ifndef DISHSW_CONTACTHOLDER__VERSION
    #define DISHSW_CONTACTHOLDER__VERSION "0.0.0"
#endif

#ifndef DISHSW_CONTACTHOLDER__VERSION_MAJOR
    #define DISHSW_CONTACTHOLDER__VERSION_MAJOR 0
#endif

#ifndef DISHSW_CONTACTHOLDER__VERSION_MINOR
    #define DISHSW_CONTACTHOLDER__VERSION_MINOR 0
#endif

#ifndef DISHSW_CONTACTHOLDER__VERSION_PATCH
    #define DISHSW_CONTACTHOLDER__VERSION_PATCH 0
#endif

#ifndef DISHSW_CONTACTHOLDER__GIT_COMMIT_SHA
    #define DISHSW_CONTACTHOLDER__GIT_COMMIT_SHA "UNKNOWN"
#endif

namespace DishSW::ContactHolder {
    inline constexpr const char* version() noexcept {
        return DISHSW_CONTACTHOLDER__VERSION;
    }

    inline constexpr unsigned int versionMajor() noexcept {
        return DISHSW_CONTACTHOLDER__VERSION_MAJOR;
    }

    inline constexpr unsigned int versionMinor() noexcept {
        return DISHSW_CONTACTHOLDER__VERSION_MINOR;
    }

    inline constexpr unsigned int versionPatch() noexcept {
        return DISHSW_CONTACTHOLDER__VERSION_PATCH;
    }

    inline constexpr const char* gitCommitSHA() noexcept {
        return DISHSW_CONTACTHOLDER__GIT_COMMIT_SHA;
    }
} // namespace DishSW::ContactHolder

