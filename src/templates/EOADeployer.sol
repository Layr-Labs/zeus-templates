// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {ZeusScript} from "../utils/ZeusScript.sol";
import {ScriptHelpers} from "../utils/ScriptHelpers.sol";

/**
 * @title EOADeployer
 * @notice Template for an Externally Owned Account (EOA) deploy script.
 */
abstract contract EOADeployer is ZeusScript {
    using ScriptHelpers for *;
    Deployment[] private _deployments;

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
     * Emits via ZeusDeploy event.
     */
    function runAsEOA() public {
        _runAsEOA();
    }

    /**
     * @dev Internal function to deploy contracts based on the provided addresses, environment, and parameters.
     */
    function _runAsEOA() internal virtual;

    function deployContract(string memory name, address deployedTo) internal returns (address) {
        deploySingleton(deployedTo, name);
        return deployedTo;
    }

    function deployImpl(string memory name, address deployedTo) internal returns (address) {
        deploySingleton(deployedTo, name.impl());
        return deployedTo;
    }

    function deployProxy(string memory name, address deployedTo) internal returns (address) {
        deploySingleton(deployedTo, name.proxy());
        return deployedTo;
    }

    function deploySingleton(address deployedTo, string memory name) internal {
        emit ZeusDeploy(name, deployedTo, true /* singleton */ );
        _deployments.push(Deployment(deployedTo, name, true));
        updatedContracts[name] = deployedTo;
    }

    function deployInstance(address deployedTo, string memory name) internal {
        emit ZeusDeploy(name, deployedTo, false /* singleton */ );
        _deployments.push(Deployment(deployedTo, name, false));

        uint256 count = zDeployedInstanceCount(name);
        string memory env = string.concat(name, string.concat("_", vm.toString(count)));

        updatedContracts[env] = deployedTo;
    }

    function deploys() public view returns (Deployment[] memory) {
        return _deployments;
    }
}
