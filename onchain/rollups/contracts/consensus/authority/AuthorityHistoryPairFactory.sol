// Copyright Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.8;

import {IAuthorityHistoryPairFactory} from "./IAuthorityHistoryPairFactory.sol";
import {Authority} from "./Authority.sol";
import {IAuthorityFactory} from "./IAuthorityFactory.sol";
import {History} from "../../history/History.sol";
import {IHistoryFactory} from "../../history/IHistoryFactory.sol";
import {IInputBox} from "../../inputs/IInputBox.sol";

/// @title Authority-History Pair Factory
/// @notice Allows anyone to reliably deploy a new Authority-History pair.
contract AuthorityHistoryPairFactory is IAuthorityHistoryPairFactory {
    IAuthorityFactory immutable authorityFactory;
    IHistoryFactory immutable historyFactory;

    /// @notice Constructs the factory.
    /// @param _authorityFactory The `Authority` factory
    /// @param _historyFactory The `History` factory
    constructor(
        IAuthorityFactory _authorityFactory,
        IHistoryFactory _historyFactory
    ) {
        authorityFactory = _authorityFactory;
        historyFactory = _historyFactory;

        emit AuthorityHistoryPairFactoryCreated(
            _authorityFactory,
            _historyFactory
        );
    }

    function getAuthorityFactory()
        external
        view
        override
        returns (IAuthorityFactory)
    {
        return authorityFactory;
    }

    function getHistoryFactory()
        external
        view
        override
        returns (IHistoryFactory)
    {
        return historyFactory;
    }

    function newAuthorityHistoryPair(
        address _authorityOwner,
        IInputBox _inputBox
    ) external override returns (Authority authority_, History history_) {
        authority_ = authorityFactory.newAuthority(address(this), _inputBox);
        history_ = historyFactory.newHistory(address(authority_));

        authority_.setHistory(history_);
        authority_.transferOwnership(_authorityOwner);
    }

    function newAuthorityHistoryPair(
        address _authorityOwner,
        IInputBox _inputBox,
        bytes32 _salt
    ) external override returns (Authority authority_, History history_) {
        authority_ = authorityFactory.newAuthority(
            address(this),
            _inputBox,
            _salt
        );
        history_ = historyFactory.newHistory(address(authority_), _salt);

        authority_.setHistory(history_);
        authority_.transferOwnership(_authorityOwner);
    }

    function calculateAuthorityHistoryAddressPair(
        IInputBox _inputBox,
        bytes32 _salt
    )
        external
        view
        override
        returns (address authorityAddress_, address historyAddress_)
    {
        authorityAddress_ = authorityFactory.calculateAuthorityAddress(
            address(this),
            _inputBox,
            _salt
        );
        historyAddress_ = historyFactory.calculateHistoryAddress(
            authorityAddress_,
            _salt
        );
    }
}
