// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the ContactHolder project.
// The MIT license text is available in the LICENSE file
// located at the root directory of the project.

#include "CMagneto/Core/HierarchicalID.hpp"

#include <algorithm>
#include <iterator>
#include <stdexcept>
#include <utility>


namespace CMagneto::Core {


    namespace {
        void verifyValidLeaf(const std::string_view iLeaf) {
            if (HierarchicalID::isLeafValid(iLeaf))
                return;

            throw std::invalid_argument("CMagneto::Core::verifyValidLeaf: HierarchicalID leaf must be non-empty and must not contain '/'.");
        }


        template <std::ranges::input_range LeafsRange>
            requires
                requires(
                    const std::ranges::range_reference_t<LeafsRange> iLeaf
                ) {
                    std::string_view{iLeaf};
                }
        void verifyValidLeafs(const LeafsRange& iLeafs) {
            if (HierarchicalID::areLeafsValid(iLeafs))
                return;

            throw std::invalid_argument("CMagneto::Core::verifyValidLeafs: HierarchicalID leaves must be non-empty and must not contain '/'.");
        }


        [[nodiscard]] std::string appendLeafsToString(
            const std::string_view iParentStringID,
            const std::vector<std::string>& iLeafs
        ) {
            std::size_t totalSize = iParentStringID.size();
            for (const std::string& leaf : iLeafs) {
                totalSize += 1 + leaf.size();
            }

            std::string stringID;
            stringID.reserve(totalSize);
            stringID.append(iParentStringID);

            for (const std::string& leaf : iLeafs) {
                stringID.push_back(HierarchicalID::kLeafSeparator);
                stringID.append(leaf);
            }

            return stringID;
        }


        /** \param iLeafsString Must not start with `kLeafSeparator`. */
        [[nodiscard]] std::vector<std::string> leafsStringToLeafs(const std::string_view iLeafsString) {
            std::vector<std::string> leafs;
            if (iLeafsString.empty())
                return leafs;

            leafs.reserve(
                1 + static_cast<std::size_t>(
                    std::count(iLeafsString.begin(), iLeafsString.end(), HierarchicalID::kLeafSeparator)
                )
            );

            std::size_t leafBeginPos = 0;
            while (true) {
                const std::size_t separatorPos = iLeafsString.find(HierarchicalID::kLeafSeparator, leafBeginPos);
                const std::size_t leafLength =
                    separatorPos == std::string_view::npos ?
                        std::string_view::npos :
                        separatorPos - leafBeginPos
                ;

                const std::string_view leaf = iLeafsString.substr(leafBeginPos, leafLength);
                verifyValidLeaf(leaf);
                leafs.emplace_back(leaf);

                if (separatorPos == std::string_view::npos)
                    return leafs;

                leafBeginPos = separatorPos + 1;
            }
        }
    } // namespace


    /*static*/ std::vector<std::string> HierarchicalID::stringIDToLeafs(
        const std::string_view iStringID,
        size_t iExpectedNumOfLeafs
    ) {
        std::vector<std::string> leafs;

        if (iStringID.empty() || iStringID.front() != kLeafSeparator)
            return leafs;

        if (iExpectedNumOfLeafs == 0) {
            iExpectedNumOfLeafs = static_cast<std::size_t>(
                std::count(iStringID.begin(), iStringID.end(), kLeafSeparator)
            );
        }

        leafs.reserve(iExpectedNumOfLeafs);

        std::size_t leafBeginPos = 1;
        while (true) {
            const std::size_t separatorPos = iStringID.find(kLeafSeparator, leafBeginPos);
            const std::size_t leafLength =
                separatorPos == std::string_view::npos ?
                    std::string_view::npos :
                    separatorPos - leafBeginPos
            ;

            if (!isLeafValid(iStringID.substr(leafBeginPos, leafLength))) {
                leafs.clear();
                return leafs;
            }

            leafs.emplace_back(iStringID.substr(leafBeginPos, leafLength));

            if (separatorPos == std::string_view::npos)
                return leafs;

            leafBeginPos = separatorPos + 1;
        }
    }


    HierarchicalID::HierarchicalID(const std::string_view iStringID)
    :
        HierarchicalID([iStringID]() {
            const std::vector<std::string> leafs = stringIDToLeafs(iStringID);
            if (leafs.empty())
                throw std::invalid_argument("CMagneto::Core::HierarchicalID: iStringID is invalid.");

            return UncheckedInitArgs{std::string{iStringID}, std::move(leafs)};
        }())
    {}


    HierarchicalID::HierarchicalID(const HierarchicalID& iParentID, const std::string_view iLeafsString)
    :
        HierarchicalID([&iParentID, iLeafsString]() {
            const std::vector<std::string> leafs = leafsStringToLeafs(iLeafsString);
            UncheckedInitArgs uncheckedInitArgs;
            uncheckedInitArgs.mStringID = appendLeafsToString(iParentID.mStringID, leafs);

            uncheckedInitArgs.mLeafs = iParentID.mLeafs;
            uncheckedInitArgs.mLeafs.reserve(uncheckedInitArgs.mLeafs.size() + leafs.size());
            uncheckedInitArgs.mLeafs.insert(uncheckedInitArgs.mLeafs.end(), leafs.begin(), leafs.end());

            return uncheckedInitArgs;
        }())
    {}


    HierarchicalID::HierarchicalID(const HierarchicalID& iParentID, const std::vector<std::string_view>& iLeafs)
    :
        HierarchicalID([&iParentID, &iLeafs]() {
            verifyValidLeafs(iLeafs);

            UncheckedInitArgs uncheckedInitArgs;

            std::size_t totalSize = iParentID.mStringID.size();
            for (const std::string_view leaf : iLeafs) {
                totalSize += 1 + leaf.size();
            }

            uncheckedInitArgs.mStringID.reserve(totalSize);
            uncheckedInitArgs.mStringID.append(iParentID.mStringID);
            for (const std::string_view leaf : iLeafs) {
                uncheckedInitArgs.mStringID.push_back(kLeafSeparator);
                uncheckedInitArgs.mStringID.append(leaf);
            }

            uncheckedInitArgs.mLeafs = iParentID.mLeafs;
            uncheckedInitArgs.mLeafs.reserve(uncheckedInitArgs.mLeafs.size() + iLeafs.size());
            for (const std::string_view leaf : iLeafs) {
                uncheckedInitArgs.mLeafs.emplace_back(leaf);
            }

            return uncheckedInitArgs;
        }())
    {}


    HierarchicalID::HierarchicalID(const HierarchicalID& iParentID, const std::vector<std::string>& iLeafs)
    :
        HierarchicalID([&iParentID, &iLeafs]() {
            verifyValidLeafs(iLeafs);

            UncheckedInitArgs uncheckedInitArgs;
            uncheckedInitArgs.mStringID = appendLeafsToString(iParentID.mStringID, iLeafs);

            uncheckedInitArgs.mLeafs = iParentID.mLeafs;
            uncheckedInitArgs.mLeafs.reserve(uncheckedInitArgs.mLeafs.size() + iLeafs.size());
            uncheckedInitArgs.mLeafs.insert(uncheckedInitArgs.mLeafs.end(), iLeafs.begin(), iLeafs.end());

            return uncheckedInitArgs;
        }())
    {}


    HierarchicalID::HierarchicalID(const HierarchicalID& iParentID, std::vector<std::string> iLeafs)
    :
        HierarchicalID([&iParentID, &iLeafs]() {
            verifyValidLeafs(iLeafs);

            UncheckedInitArgs uncheckedInitArgs;
            uncheckedInitArgs.mStringID = appendLeafsToString(iParentID.mStringID, iLeafs);

            uncheckedInitArgs.mLeafs = iParentID.mLeafs;
            uncheckedInitArgs.mLeafs.reserve(uncheckedInitArgs.mLeafs.size() + iLeafs.size());
            uncheckedInitArgs.mLeafs.insert(
                uncheckedInitArgs.mLeafs.end(),
                std::make_move_iterator(iLeafs.begin()),
                std::make_move_iterator(iLeafs.end())
            );

            return uncheckedInitArgs;
        }())
    {}


    bool HierarchicalID::isAncestorOf(const HierarchicalID& iOther) const noexcept {
        if (mLeafs.size() >= iOther.mLeafs.size())
            return false;

        return std::equal(mLeafs.begin(), mLeafs.end(), iOther.mLeafs.begin());
    }


    std::vector<std::string> HierarchicalID::relativeLeafs(const HierarchicalID& iOther) const {
        const std::span<const std::string> leafsSpan = relativeLeafsAsSpan(iOther);
        return {leafsSpan.begin(), leafsSpan.end()};
    }


    std::string HierarchicalID::relativeLeafsAsString(const HierarchicalID& iOther) const {
        const std::string_view leafsStringView = relativeLeafsAsStringView(iOther);
        return std::string{leafsStringView};
    }


    std::string_view HierarchicalID::relativeLeafsAsStringView(const HierarchicalID& iOther) const noexcept {
        const std::size_t beginPos = relativeLeafsBeginPos(iOther);
        if (beginPos >= mLeafs.size())
            return {};

        return std::string_view{mStringID}.substr(iOther.mStringID.size() + 1);
    }


    std::span<const std::string> HierarchicalID::relativeLeafsAsSpan(const HierarchicalID& iOther) const noexcept {
        const std::size_t beginPos = relativeLeafsBeginPos(iOther);
        return std::span<const std::string>{mLeafs}.subspan(beginPos);
    }


    HierarchicalID::LeafsRange HierarchicalID::relativeLeafsAsRange(const HierarchicalID& iOther) const noexcept {
        const std::size_t beginPos = relativeLeafsBeginPos(iOther);
        return LeafsRange{
            mLeafs.begin() + static_cast<std::ptrdiff_t>(beginPos),
            mLeafs.end()
        };
    }


    bool HierarchicalID::operator==(const HierarchicalID& iOther) const noexcept {
        return mStringID == iOther.mStringID;
    }


    bool HierarchicalID::operator<(const HierarchicalID& iOther) const noexcept {
        return mStringID < iOther.mStringID;
    }


    HierarchicalID::HierarchicalID(UncheckedInitArgs iUncheckedInitArgs) noexcept
    :
        mStringID(std::move(iUncheckedInitArgs.mStringID)),
        mLeafs(std::move(iUncheckedInitArgs.mLeafs))
    {}


    std::size_t HierarchicalID::relativeLeafsBeginPos(const HierarchicalID& iOther) const noexcept {
        if (!iOther.isAncestorOf(*this))
            return mLeafs.size();

        return iOther.mLeafs.size();
    }


} // namespace CMagneto::Core
