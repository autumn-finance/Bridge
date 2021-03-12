// SPDX-License-Identifier: MIT

/*
 * This file is part of the Autumn Cross-Chain Bridge Smart Contract
 */

pragma solidity ^0.7.3;

import { Ownable } from "./vendor/Ownable.sol";
import { SafeMath } from "./vendor/SafeMath.sol";

// A decentralized verification implementation for
// approving allowance for withdraw or mint of the Cross-Chain Bridge

abstract contract Witness is Ownable {
    using SafeMath for uint256;

    bytes constant internal NO_ERROR = new bytes(0);

    /*
     * Storage
     */

    struct WitnessData {
        // Whether the burn is witnessed by enough witnesses
        bool approved;

        // The local chain address to receive the witness allowance
        address to;

        // The burnt amount of equivalent cross-chain assets
        uint256 amount;

        // the witness count of this burnt
        uint256 witness;
    }

    /// @dev Burn transaction hash to its data
    mapping (string => WitnessData) public witnessData;

    /// @dev All witnesses of burns
    mapping (string => address[]) public txWitnesses;

    /// @dev The allowance amount of user for the operation need witness
    mapping (address => uint256) public witnessedAllowance;

    /*
     * Control
     */

    /// @dev the minimum amount of witness required to approve a burn
    uint256 minimumWitness;

    function setMinimumWitness(uint256 min) onlyOwner() external {
        minimumWitness = min;
    }

    /*
     * Permission
     */

    /// @dev The permission of witness accounts
    mapping (address => bool) public witnessPermission;

    /// @dev The array of all witnesses for quering
    address[] public witnessList;

    function setWitnessPermission(address guy, bool permit) onlyOwner() external {
        require(witnessPermission[guy] != permit, "Permission already set");
        witnessPermission[guy] = permit;

        if (permit) {
            witnessList.push(guy);
        } else {
            uint256 atArray;
            for (uint256 i = 0; i < witnessList.length; i++) {
                if (witnessList[i] == guy) {
                    atArray = i;
                    break;
                }
            }
            witnessList[atArray] = witnessList[witnessList.length - 1];
            witnessList.pop();
        }

        emit WitnessPermissionUpdated(guy, permit);
    }

    event WitnessPermissionUpdated(address witness, bool permit);

    /*
     * Entrances
     */

     /**
     * @dev Checks the eligibility of the witness to verify the deposit transaction
     *
     *  It checks following requirements:
     *  - The witness account have correct permission
     *  - The deposit transaction have not been approved yet
     *  - The witness have not verified this deposit before
     */
    function canWitness(address guy, string memory hash)
        public
        view
        returns (bytes memory error)
    {
        if (!witnessPermission[guy]) {
            return "No permission";
        }

        if (witnessData[hash].approved) {
            return "Already approved";
        }

        address[] memory witnesses_ = txWitnesses[hash];
        for (uint256 i = 0; i < witnesses_.length; i++) {
            if (witnesses_[i] == guy) {
                return "Already witnessed";
            }
        }

        return NO_ERROR;
    }

    /**
     * @notice Witness a burn on the other chain with target account on the local chain
     *  Call `canWitness` to check the eligibility
     */
    function witness(string memory hash, address to, uint256 amount)
        external
        returns (bool)
    {
        bytes memory error = canWitness(_msgSender(), hash);
        require(error.length == 0, string(error));

        WitnessData memory data = witnessData[hash];

        // setup the amount and to, all witness have to be the same for one tx
        if (data.amount == 0) {
            witnessData[hash].amount = amount;
            witnessData[hash].to = to;
        } else {
            // something was wrong, need a restart
            require(data.amount == amount, "Witness amount inconsistent");
            require(data.to == to, "Witness to inconsistent");
        }

        txWitnesses[hash].push(_msgSender());
        uint256 count = witnessData[hash].witness = data.witness.add(1);
        emit WitnessVisited(hash, to, amount, _msgSender());

        // check for witness count
        if (count >= minimumWitness) {
            witnessData[hash].approved = true;
            witnessedAllowance[to] = witnessedAllowance[to].add(amount);
            emit WitnessApproved(hash, to, amount);
        }

        return true;
    }

    /// @dev Emits when a tx finally approved by enough witnesses
    event WitnessApproved(string indexed burnTx, address indexed to, uint256 amount);

    /// @dev Emits everytime when a witness applied to the (unapprove yet) tx
    event WitnessVisited (string indexed burnTx, address indexed to, uint256 amount, address witness);

    /**
     * @dev Forcily restart the witness program to a cross-chain tx
     *  in case it got stuck due to amount inconsistent, etc.
     */
    function restartWitness(string memory hash)
        onlyOwner()
        external
    {
        require(!witnessData[hash].approved, "restartVerification: Already approved");
        delete witnessData[hash];
        delete txWitnesses[hash];
    }
}