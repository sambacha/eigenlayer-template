// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {TokenMessage} from "../libs/TokenMessage.sol";
import {HypERC20Collateral} from "../HypERC20Collateral.sol";
import {TypeCasts} from "../../libs/TypeCasts.sol";

/**
 * @title ERC4626 Token Collateral with deposits collateral to a vault
 * @author Abacus Works
 */
contract HypERC4626Collateral is HypERC20Collateral {
    using TypeCasts for address;
    using TokenMessage for bytes;
    using Math for uint256;

    // Address of the ERC4626 compatible vault
    ERC4626 public immutable vault;
    uint256 public constant PRECISION = 1e10;
    bytes32 public constant NULL_RECIPIENT =
        0x0000000000000000000000000000000000000000000000000000000000000001;

    constructor(
        ERC4626 _vault,
        address _mailbox
    ) HypERC20Collateral(_vault.asset(), _mailbox) {
        vault = _vault;
    }

    function initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) public override initializer {
        _MailboxClient_initialize(_hook, _interchainSecurityModule, _owner);
    }

    function _transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount,
        uint256 _value,
        bytes memory _hookMetadata,
        address _hook
    ) internal virtual override returns (bytes32 messageId) {
        // Can't override _transferFromSender only because we need to pass shares in the token message
        _transferFromSender(_amount);
        uint256 _shares = _depositIntoVault(_amount);
        uint256 _exchangeRate = PRECISION.mulDiv(
            vault.totalAssets(),
            vault.totalSupply(),
            Math.Rounding.Down
        );
        bytes memory _tokenMetadata = abi.encode(_exchangeRate);

        bytes memory _tokenMessage = TokenMessage.format(
            _recipient,
            _shares,
            _tokenMetadata
        );

        messageId = _Router_dispatch(
            _destination,
            _value,
            _tokenMessage,
            _hookMetadata,
            _hook
        );

        emit SentTransferRemote(_destination, _recipient, _shares);
    }

    /**
     * @dev Deposits into the vault and increment assetDeposited
     * @param _amount amount to deposit into vault
     */
    function _depositIntoVault(uint256 _amount) internal returns (uint256) {
        wrappedToken.approve(address(vault), _amount);
        return vault.deposit(_amount, address(this));
    }

    /**
     * @dev Transfers `_amount` of `wrappedToken` from this contract to `_recipient`, and withdraws from vault
     * @inheritdoc HypERC20Collateral
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata
    ) internal virtual override {
        // withdraw with the specified amount of shares
        vault.redeem(_amount, _recipient, address(this));
    }

    /**
     * @dev Update the exchange rate on the synthetic token by accounting for additional yield accrued to the underlying vault
     * @param _destinationDomain domain of the vault
     */
    function rebase(uint32 _destinationDomain) public payable {
        // force a rebase with an empty transfer to 0x1
        _transferRemote(
            _destinationDomain,
            NULL_RECIPIENT,
            0,
            msg.value,
            bytes(""),
            address(0)
        );
    }
}
