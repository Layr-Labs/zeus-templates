// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {ZeusScript} from "../utils/ZeusScript.sol";

/**
 * @title EOADeployer
 * @notice Template for an Externally Owned Account (EOA) deploy script.
 */
abstract contract EOADeployer is ZeusScript {
    /**
     * @notice Struct for deployment information.
     * @param deployedTo The address where the contract is deployed.
     * @param name The name of the deployed contract.
     * @param singleton True to have Zeus track this contract within the config. Use for contracts with meaningful identity (e.g. _the_ EigenPodManager implementation).
     */
    struct Deployment {
        address deployedTo;
        string name;
        bool singleton;
    }

    /**
     * @notice Deploys contracts based on the configuration specified in the provided environment file.
     * @return An array of Deployment structs containing information about the deployed contracts.
     */
    function deploy() public returns (Deployment[] memory) {
        // return deployment info
        return _deploy();
    }

    /**
     * @dev Internal function to deploy contracts based on the provided addresses, environment, and parameters.
     * @return An array of Deployment structs representing the deployed contracts.
     */
    function _deploy() internal virtual returns (Deployment[] memory);

    function singleton(address deployedTo, string memory name) internal pure returns (Deployment memory) {
        return Deployment({
            deployedTo: deployedTo,
            name: name,
            singleton: true
        });
    }

    function instance(address deployedTo, string memory name) internal pure returns (Deployment memory) {
        return Deployment({
            deployedTo: deployedTo,
            name: name,
            singleton: false
        });
    }
}
