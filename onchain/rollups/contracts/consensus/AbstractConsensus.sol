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

import {IConsensus} from "./IConsensus.sol";

/// @title Abstract Consensus
/// @notice An abstract contract that partially implements `IConsensus`.
abstract contract AbstractConsensus is IConsensus {
    /// @notice Emits an `ApplicationJoined` event with the message sender.
    function join() external override {
        emit ApplicationJoined(msg.sender);
    }
}
