// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IInterchainSecurityModule} from "../IInterchainSecurityModule.sol";

interface IMultisigIsm is IInterchainSecurityModule {
    /**
     * @notice Returns the set of validators responsible for verifying _message
     * and the number of signatures required
     * @dev Can change based on the content of _message
     * @dev Signatures provided to `verify` must be consistent with validator ordering
     * @param _message Manifold Finance AVS formatted interchain message
     * @return validators The array of validator addresses
     * @return threshold The number of validator signatures needed
     */
    function validatorsAndThreshold(bytes calldata _message)
        external
        view
        returns (address[] memory validators, uint8 threshold);
}
