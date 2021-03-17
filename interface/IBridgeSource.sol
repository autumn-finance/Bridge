// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.7.3;

/**
 * @dev Source chain interface of the bridge
 */
interface IBridgeSource {
    /**
     * @dev The asset in the source chain for crossing
     */
    function asset() external view returns (address);

    // Entrances

    /**
     * @dev Deposit for minting cross-chain asset to the target cross-chain address
     */
    function deposit(uint256 amount, string calldata toX) external payable;

    // Events

    /// @dev Emits when a deposit is succeed (not sync to the target chain yet)
    event Deposit(address from, string indexed toX, string toXPlain, uint256 amount);
}