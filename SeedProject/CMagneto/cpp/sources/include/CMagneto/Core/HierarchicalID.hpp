// Copyright (c) Dmitrii Shvydkoi ("Dim Shvydkoy")
// SPDX-License-Identifier: MIT
//
// This file is part of the CMagneto Framework.
// It is licensed under the MIT license found in the LICENSE file
// located at the root directory of the CMagneto Framework.
//
// By default, the CMagneto Framework root resides at the root of the project where it is used,
// but consumers may relocate it as needed.

#pragma once

#include <cstddef>
#include <concepts>
#include <ranges>
#include <span>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>


namespace CMagneto::Core {


    /**
     * Hierarchical slash-separated ID like `/MainWindow/Settings`.
     * Each leaf must be non-empty and must not contain `/`.
     *
     * The class owns both the string form and the parsed leaf list.
     * Thus, it provides cheap string access and efficient leaf operations.
     */
    class HierarchicalID {
    public:
        using LeafsConstIterator = std::vector<std::string>::const_iterator;
        using LeafsRange = std::ranges::subrange<LeafsConstIterator>;

        inline static constexpr char kLeafSeparator{'/'};

        /** \returns false, if empty or contains `kLeafSeparator`. */
        [[nodiscard]] static constexpr bool isLeafValid(const std::string_view iLeaf) noexcept {
            return !iLeaf.empty() && iLeaf.find(kLeafSeparator) == std::string_view::npos;
        }

        /** \returns false, if has an invalid leaf. */
        template <std::ranges::input_range LeafsRange> // <== `LeafsRange` must satisfy the `std::ranges::input_range` concept.
            // `LeafsRange` here is a template parameter name.
            // It is not the same as `HierarchicalID::LeafsRange`.
            requires // <== Part of template syntax.
                     //     ^ Means "this template is only available if the following condition is satisfied".
                     //
                requires( // <== A requires-expression begin.                               // |
                    const std::ranges::range_reference_t<LeafsRange> iLeaf                  // |
                    // ^== The reference type produced by dereferencing the range iterator. // | The type must be usable
                ) {                                                                         // | to construct `std::string_view`.
                    std::string_view{iLeaf};                                                // |
                }                                                                           // |
        [[nodiscard]] static bool areLeafsValid(const LeafsRange& iLeafs) noexcept {
            for (const auto& leaf : iLeafs) {
                if (!isLeafValid(std::string_view{leaf}))
                    return false;
            }

            return true;
        }

        /** \returns false, if has an invalid leaf or starts not with `kLeafSeparator`. */
        [[nodiscard]] static constexpr bool isStringIDValid(const std::string_view iStringID) noexcept {
            if (iStringID.empty() || iStringID.front() != kLeafSeparator)
                return false;

            std::size_t leafBeginPos = 1;
            while (true) {
                const std::size_t separatorPos = iStringID.find(kLeafSeparator, leafBeginPos);
                const std::size_t leafLength =
                    separatorPos == std::string_view::npos ?
                        std::string_view::npos :
                        separatorPos - leafBeginPos
                ;

                if (!isLeafValid(iStringID.substr(leafBeginPos, leafLength)))
                    return false;

                if (separatorPos == std::string_view::npos)
                    return true;

                leafBeginPos = separatorPos + 1;
            }
        }

        /**
         * \returns Empty vector, if `iStringID` has an invalid leaf or starts not with `kLeafSeparator`.
         * \param iExpectedNumOfLeafs Initial capacity of leaf vector. If 0, number of separators is counted in advance.
         * */
        [[nodiscard]] static std::vector<std::string> stringIDToLeafs(
            const std::string_view iStringID,
            size_t iExpectedNumOfLeafs = 0
        );

        explicit HierarchicalID(const std::string_view iStringID);
        HierarchicalID(const HierarchicalID& iParentID, const std::string_view iLeafsString);
        HierarchicalID(const HierarchicalID& iParentID, const std::vector<std::string_view>& iLeafs);
        HierarchicalID(const HierarchicalID& iParentID, const std::vector<std::string>& iLeafs);
        HierarchicalID(const HierarchicalID& iParentID, std::vector<std::string> iLeafs);

        template <std::ranges::input_range LeafsRange>
            requires
                requires(const std::ranges::range_reference_t<LeafsRange> iLeaf) {
                    std::string_view{iLeaf};
                }
        HierarchicalID(const HierarchicalID& iParentID, const LeafsRange& iLeafs)
        :
            HierarchicalID([&iParentID, &iLeafs]() {
                UncheckedInitArgs uncheckedInitArgs;

                if constexpr (std::ranges::forward_range<LeafsRange>) {
                    // If the range is a `forward_range`, it can be safely iterated more than once.
                    // That allows a first pass for sizing, then a second pass for filling.

                    std::size_t totalSize = iParentID.mStringID.size();
                    std::size_t numOfLeafs = 0;
                    for (const std::string_view leaf : iLeafs) {
                        if (!isLeafValid(leaf))
                            throw std::invalid_argument("CMagneto::Core::HierarchicalID: iLeafs has invalid leaf.");

                        totalSize += 1 + leaf.size();
                        ++numOfLeafs;
                    }

                    uncheckedInitArgs.mStringID.reserve(totalSize);
                    uncheckedInitArgs.mLeafs.reserve(iParentID.mLeafs.size() + numOfLeafs);
                }
                else if constexpr (std::ranges::sized_range<LeafsRange>) {
                    // If the range is not a `forward_range`, but is a `sized_range`, at least it is known how many elements the range has.
                    // Avoid a two-pass walk for string sizing, since a pure input range may not support that safely.

                    uncheckedInitArgs.mLeafs.reserve(
                        iParentID.mLeafs.size() + static_cast<std::size_t>(std::ranges::size(iLeafs))
                    );
                }

                uncheckedInitArgs.mLeafs.insert(
                    uncheckedInitArgs.mLeafs.end(),
                    iParentID.mLeafs.begin(),
                    iParentID.mLeafs.end()
                );

                uncheckedInitArgs.mStringID.append(iParentID.mStringID);
                for (const std::string_view leaf : iLeafs) {
                    // The filling pass over `iLeafs`.

                    if constexpr (!std::ranges::forward_range<LeafsRange>) {
                        // The check is already done for `forward_range`.

                        if (!isLeafValid(leaf))
                            throw std::invalid_argument("CMagneto::Core::HierarchicalID: iLeafs has invalid leaf.");
                    }

                    uncheckedInitArgs.mStringID.push_back(kLeafSeparator);
                    uncheckedInitArgs.mStringID.append(leaf);
                    uncheckedInitArgs.mLeafs.emplace_back(leaf);
                }

                return uncheckedInitArgs;
            }())
        {}

        [[nodiscard]] const std::string& stringID() const noexcept {
            return mStringID;
        }

        [[nodiscard]] const std::vector<std::string>& leafs() const noexcept {
            return mLeafs;
        }

        [[nodiscard]] bool isAncestorOf(const HierarchicalID& iOther) const noexcept;

        /** \returns Leafs of `this` relative to `iOther`. Empty, if `iOther` is not ancestor of `this`. */
        [[nodiscard]] std::vector<std::string> relativeLeafs(const HierarchicalID& iOther) const;

        /** \returns Leafs of `this` relative to `iOther`. Empty, if `iOther` is not ancestor of `this`. The string has no leading `kLeafSeparator`. */
        [[nodiscard]] std::string relativeLeafsAsString(const HierarchicalID& iOther) const;

        /** \returns Leafs of `this` relative to `iOther`. Empty, if `iOther` is not ancestor of `this`. The string has no leading `kLeafSeparator`. */
        [[nodiscard]] std::string_view relativeLeafsAsStringView(const HierarchicalID& iOther) const noexcept;

        /** \returns Leafs of `this` relative to `iOther`. Empty, if `iOther` is not ancestor of `this`. */
        [[nodiscard]] std::span<const std::string> relativeLeafsAsSpan(const HierarchicalID& iOther) const noexcept;

        /** \returns Leafs of `this` relative to `iOther`. Empty, if `iOther` is not ancestor of `this`. */
        [[nodiscard]] LeafsRange relativeLeafsAsRange(const HierarchicalID& iOther) const noexcept;

        [[nodiscard]] bool operator==(const HierarchicalID& iOther) const noexcept;

        [[nodiscard]] bool operator<(const HierarchicalID& iOther) const noexcept;

    private:


        /** `HierarchicalID` constructor do not check validity of the data. */
        struct UncheckedInitArgs {
            std::string mStringID;
            std::vector<std::string> mLeafs;
        };


        explicit HierarchicalID(UncheckedInitArgs iUncheckedInitArgs) noexcept;
        [[nodiscard]] std::size_t relativeLeafsBeginPos(const HierarchicalID& iOther) const noexcept;

        std::string mStringID;
        std::vector<std::string> mLeafs;
    }; // class HierarchicalID


} // namespace CMagneto::Core
