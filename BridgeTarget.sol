// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.7.3;

import { ERC20 } from "./vendor/ERC20.sol";
import { Witness } from "./Witness.sol";
import { IBridgeTarget } from "./interface/IBridgeTarget.sol";

// This contract implements the target chain part of Cross-Chain Asset Bridge.
// See comment on `BridgeSource` for more information.

contract BridgeTarget is IBridgeTarget, Witness, ERC20 {

    /// @dev The symbol of the asset in the source chain
    string public override asset;

    constructor(
        string memory assetName,
        string memory xAssetName,
        string memory xAssetSymbol,
        uint8 assetDecimals)
    ERC20(
        xAssetName, xAssetSymbol, assetDecimals
    ) {
        asset = assetName;
    }

    // IBridgeTarget overrides

    function mintOf(address guy) external override view returns (uint256) {
        return witnessedAllowance[guy];
    }

    /// @dev Burns with specific source chain address to receive allowance of withdraw
    function burn(address account, string memory toSource, uint256 amount) external override {
        // from ERC20Burnable
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "Burn amount exceeds allowance");

        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
        emit Burn(account, toSource, amount);
    }

    /// @dev Mints (claims) all available cross-chain assets that approved by witness
    function mint() external override {
        uint256 allowance = witnessedAllowance[_msgSender()];
        require(allowance != 0, "No available cross-chain asset to mint");

        witnessedAllowance[_msgSender()] = 0;
        _mint(_msgSender(), allowance);
        emit Mint(_msgSender(), allowance);
    }
}