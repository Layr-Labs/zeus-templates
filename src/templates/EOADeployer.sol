// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {Addresses, Environment, Params, ConfigParser} from "../utils/ConfigParser.sol";

/**
 * @title EOADeployer
 * @notice Template for an Externally Owned Account (EOA) deploy script.
 */
abstract contract EOADeployer is ConfigParser {
    /**
     * @notice Struct for deployment information.
     * @param deployedTo The address where the contract is deployed.
     * @param override The overridden name of the deployed contract. Leave empty for Zeus to use the default contract name. Otherwise, Zeus will override it if specified.
     * @param singleton True to have Zeus track this contract within the config. Use for contracts with meaningful identity (e.g. _the_ EigenPodManager implementation).
     */
    struct Deployment {
        address deployedTo;
        string overrideName;
        bool singleton;
    }

    /**
     * @notice Deploys contracts based on the configuration specified in the provided environment file.
     * @param envPath The file path to the environment configuration file.
     * @return An array of Deployment structs containing information about the deployed contracts.
     */
    function deploy(string memory envPath) public returns (Deployment[] memory) {
        // read in config file for environment
        (Addresses memory addrs, Environment memory env, Params memory params) = _readConfigFile(envPath);

        // return deployment info
        return _deploy(addrs, env, params);
    }

    /**
     * @dev Internal function to deploy contracts based on the provided addresses, environment, and parameters.
     * @param addrs Struct containing the addresses required for deployment.
     * @param env Struct containing the environment settings for deployment.
     * @param params Struct containing additional parameters for deployment.
     * @return An array of Deployment structs representing the deployed contracts.
     */
    function _deploy(Addresses memory addrs, Environment memory env, Params memory params)
        internal
        virtual
        returns (Deployment[] memory);
}
