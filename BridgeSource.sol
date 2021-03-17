// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.7.3;

import { Witness } from "./Witness.sol";
import { IBridgeSource } from "./interface/IBridgeSource.sol";
import { SafeERC20, IERC20, SafeMath } from "./vendor/SafeERC20.sol";

// This contract implements the source chain part of Cross-Chain Asset Bridge.
//
// Comprised by two parts:
// - Deposit / Withdraw
// - Witness / Approves
//
// Users can deposit without a restriction and the transaction will be actively
// found by the witness(es) who is keeping monitor on the contract.
//
// Then, the witness will submit witness on the target chain contract (not included
// within this file) and mint equivalent cross-chain asset (wBTC for example) to
// the address on the target chain specificed when deposit.
//
// Later, when the user can burn the cross-chain asset on the target chain,
// and it will be found by witness(es) and submit witness on this contract.
//
// When the witness count is enough (as specified by `minimumWitness`), the burning
// is identified as 'approved'. While an allowance of withdraw in the amount of
// the burnt equivalent cross-chain asset will be added to the source chain address
// (will be specificed by user when burning on the target chain) and user are
// able to withdraw his deposited asset.
//
// The witness program in both chains are in the similar way.
// `toSource` refers to the address on the source (current) chain
// `toX` refers to the address on the target (crossing) chain

contract BridgeSource is IBridgeSource, Witness {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Deposit Control

    /// @dev The minimum amount of asset to deposit
    uint256 public minimumDeposit;

    function setMinDeposit(uint256 minDeposit_) onlyOwner() external {
        minimumDeposit = minDeposit_;
    }

    // Asset
    
    IERC20 internal _asset;

    function asset() external override view returns (address) {
        return address(_asset);
    }

    /**
     * @dev Whether the asset is the native currency on local chain
     */
    bool public native;

    // Fee Control

    /// @dev A fixed fee to be charged when deposit
    uint256 public feeFixed;

    /// @dev The allocated fee could be claimed
    uint256 public feeAllocated;

    /// @dev The recipient to receive the fee when claiming
    address payable public feeRecipient;

    function setFeeFixed(uint256 feeFixed_) onlyOwner() external {
        feeFixed = feeFixed_;
    }

    function setFeeRecipient(address payable recipient_) onlyOwner() external {
        feeRecipient = recipient_;
    }

    function claimAllocatedFee() external { // public
        require(feeRecipient != address(0), "No fee recipient");
        require(feeAllocated != 0, "No fee allocated yet");
        if (native) {
            feeRecipient.transfer(feeAllocated);
        } else {
            _asset.safeTransfer(feeRecipient, feeAllocated);
        }
        feeAllocated = 0;
    }

    constructor(address asset_, bool native_, uint256 minDeposit_) {
        _asset = IERC20(asset_);
        native = native_;

        if (native) {
            // ensures asset is given correctly
            require(
                asset_ == address(0),
                "Asset should be zero address for native currency"
            );
        }
        
        minimumDeposit = minDeposit_;
    }

    bool public paused = false;

    function setPasued(bool paused_) onlyOwner() external {
        paused = paused_;
    }

    // IBridgeSource overrides

    function deposit(uint256 amount, string calldata toX) external override payable {
        require(!paused, "Paused");
        uint256 amount_ = amount;
        if (native) {
            require(msg.value == amount_, "Inconsistent with amount and value");
        } else {
            require(msg.value == 0, "Non-native asset cannot have a value");

            uint256 before = _asset.balanceOf(address(this));
            _asset.safeTransferFrom(_msgSender(), address(this), amount_);
            amount_ = _asset.balanceOf(address(this)).sub(before);
        }

        require(amount_ >= minimumDeposit, "Amount smaller than minimum");
        amount_ = _chargeForFixedFee(amount_);

        emit Deposit(_msgSender(), toX, toX, amount_);
    }

    function _chargeForFixedFee(uint256 amount) private returns (uint256) {
        require(amount > feeFixed, "Amount less than fee");
        amount = amount.sub(feeFixed);
        feeAllocated = feeAllocated.add(feeFixed);
        return amount;
    }

    // Witness overrides

    function onWitnessApproved(string memory txHash, address payable to, uint256 amount) internal override {
        txHash;
        _withdrawTo(to, amount);
    }

    /// @dev This need strict requirement checks
    function _withdrawTo(address payable to, uint256 amount) private {
        if (native) {
            to.transfer(amount);
        } else {
            IERC20(_asset).safeTransfer(to, amount);
        }
    }
}