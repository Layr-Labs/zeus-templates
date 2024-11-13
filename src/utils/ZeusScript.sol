// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {StringUtils} from "./StringUtils.sol";
import {Script} from "forge-std/Script.sol";

abstract contract ZeusScript is Script {
    using StringUtils for string;

    enum EnvironmentVariableType {
        INT_256,
        ADDRESS,
        STRING
    }

    event ZeusEnvironmentUpdate(string key, EnvironmentVariableType internalType, bytes value);

    string internal constant addressPrefix = "ZEUS_DEPLOYED_";
    string internal constant envPrefix = "ZEUS_ENV_";

    /**
     * @notice A test function to be implemented by the inheriting contract.
     */
    function zeusTest() public virtual;

    /**
     * Environment manipulation - update variables in the current environment's configuration *****
     */
    // NOTE: you do not need to use these for contract addresses, which are tracked and injected automatically.
    // NOTE: do not use `.update()` during a vm.broadcast() segment.
    function update(string memory key, string memory value) public {
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.STRING, abi.encode(value));
    }

    function update(string memory key, address value) public {
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.ADDRESS, abi.encode(value));
    }

    function update(string memory key, uint256 value) public {
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.INT_256, abi.encode(value));
    }

    /**
     * @notice Returns the address of a contract based on the provided key, querying the envvars injected by Zeus. This is typically the name of the contract.
     * @param key The key to look up the address for. Should be the contract name, with an optional suffix if deploying multiple instances. (E.g. "MyContract_1" and "MyContract_2")
     * @return The address of the contract associated with the provided key. Reverts if envvar not found.
     */
    function zDeployedContract(string memory key) internal view returns (address) {
        //                     ZEUS_DEPLOYED_ + key
        string memory envvar = addressPrefix.concat(key);
        return vm.envAddress(envvar);
    }

    /**
     * Returns an `address` set in the current environment. NOTE: If you deployed this contract with zeus, you want `zDeployedContract` instead.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function zAddress(string memory key) internal view returns (address) {
        return vm.envAddress(key);
    }

    /**
     * Returns a uin64 set in the current environment.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function zUint64(string memory key) internal view returns (uint64) {
        string memory envvar = envPrefix.concat(key);
        return uint64(vm.envUint(envvar));
    }

    /**
     * Returns a boolean set in the current environment.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function zBool(string memory key) internal view returns (bool) {
        string memory envvar = envPrefix.concat(key);
        return bool(vm.envBool(envvar));
    }

    /**
     * Returns a string set in the current environment
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function zString(string memory key) internal view returns (string memory) {
        string memory envvar = envPrefix.concat(key);
        return vm.envString(envvar);
    }
}
