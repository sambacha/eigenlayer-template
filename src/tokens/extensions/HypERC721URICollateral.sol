// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {HypERC721Collateral} from "../HypERC721Collateral.sol";

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @title ERC721 Token Collateral that wraps an existing ERC721 with remote transfer and URI relay functionality.
 * @author Abacus Works
 */
contract HypERC721URICollateral is HypERC721Collateral {
    // solhint-disable-next-line no-empty-blocks
    constructor(
        address erc721,
        address _mailbox
    ) HypERC721Collateral(erc721, _mailbox) {}

    /**
     * @dev Transfers `_tokenId` of `wrappedToken` from `msg.sender` to this contract.
     * @return The URI of `_tokenId` on `wrappedToken`.
     * @inheritdoc HypERC721Collateral
     */
    function _transferFromSender(
        uint256 _tokenId
    ) internal override returns (bytes memory) {
        HypERC721Collateral._transferFromSender(_tokenId);
        return
            bytes(
                IERC721MetadataUpgradeable(address(wrappedToken)).tokenURI(
                    _tokenId
                )
            );
    }
}
