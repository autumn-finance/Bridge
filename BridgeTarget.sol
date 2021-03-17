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

    bool public paused = false;

    function setPasued(bool paused_) onlyOwner() external {
        paused = paused_;
    }

    // IBridgeTarget overrides

    function burn(string memory toSource, uint256 amount) external override {
        burnFrom(_msgSender(), toSource, amount);
    }

    function burnFrom(address account, string memory toSource, uint256 amount) public override {
        require(!paused, "Paused");
        // from ERC20Burnable
        if (account != _msgSender()) {
            uint256 currentAllowance = allowance(account, _msgSender());
            require(currentAllowance >= amount, "Burn amount exceeds allowance");
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
        emit Burn(account, toSource, toSource, amount);
    }

    // Witness overrides

    function onWitnessApproved(string memory txHash, address payable to, uint256 amount) internal override {
        txHash;
        _mint(to, amount);
    }
}