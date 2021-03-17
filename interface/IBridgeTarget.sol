// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.7.3;

import { IERC20 } from "../vendor/IERC20.sol";

/**
 * @dev Target chain interface of the bridge
 */
interface IBridgeTarget is IERC20 {
    /**
     * @dev The asset name in the source chain for crossing
     */
    function asset() external view returns (string memory);

    // Entrances

    /**
     * @dev Burn x-asset for withdraw allowance to the source chain address
     */
    function burn(string memory toX, uint256 amount) external;

    /**
     * @dev Burn x-asset for withdraw allowance to the source chain address
     */
    function burnFrom(address account, string memory toX, uint256 amount) external;

    // Events

    /// @dev Emits when a burn is succeed (not sync to the source chain yet)
    event Burn(address indexed account, string indexed toSource, string toSourcePlain, uint256 amount);
}