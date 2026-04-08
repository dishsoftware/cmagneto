#include "CMagneto/Core/FrameworkInfo.hpp"
#include "PrivateDummy.hpp"


namespace CMagneto::Core {
    std::string_view frameworkName() noexcept {
        [[maybe_unused]] constexpr int privateDummyValue = PrivateDummy::value();
        return "CMagneto";
    }
} // namespace CMagneto::Core
