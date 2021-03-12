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

    /**
     * @dev Returns the amount of asset that could be withdrawn
     */
    function withdrawOf(address guy) external view returns (uint256);

    // Entrances

    /**
     * @dev Deposit for minting cross-chain asset to the target cross-chain address
     */
    function deposit(uint256 amount, string memory toX) external payable;

    /**
     * @dev Withdraw all available asset (by burn x-chain assets) from bridge
     */
    function withdraw() external;

    // Events

    /// @dev Emits when a deposit is succeed (not sync to the target chain yet)
    event Deposit(address from, string indexed toX, uint256 amount);

    /// @dev Emits when a withdraw is succeed
    event Withdraw(address indexed guy, uint256 amount);
}