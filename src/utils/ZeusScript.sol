// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {StringUtils} from "./StringUtils.sol";
import {Script} from "forge-std/Script.sol";

abstract contract ZeusScript is Script {
    using StringUtils for string;

    string internal constant addressPrefix = "ZEUS_DEPLOYED_";
    string internal constant envPrefix = "ZEUS_ENV_";

    /**
     * @notice A test function to be implemented by the inheriting contract.
     */
    function zeusTest() public virtual;

    /**
     * @notice Returns the address of a contract based on the provided key, querying the envvars injected by Zeus. This is typically the name of the contract.
     * @param key The key to look up the address for. Should be the contract name, with an optional suffix if deploying multiple instances. (E.g. "MyContract_1" and "MyContract_2")
     * @return The address of the contract associated with the provided key. Reverts if envvar not found.
     */
    function zeusAddress(string memory key) internal view returns (address) {
        string memory envvar = addressPrefix.concat(key);
        return vm.envAddress(envvar);
    }

    function getUint64(string memory key) internal view returns (uint64) {
        string memory envvar = envPrefix.concat(key);
        return uint64(vm.envUint(envvar));
    }

    //////////////////////////
    /// HELPER FUNCTIONS /////
    //////////////////////////

    function ethPOS() internal view returns (address) {
        return zeusAddress("ethPOS");
    }

    function EigenpodGenesisTime() internal view returns (uint64) {
        return getUint64("EIGENPOD_GENESIS_TIME");
    }

}
