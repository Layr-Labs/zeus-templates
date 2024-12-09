// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import "forge-std/Vm.sol";

enum EnvironmentVariableType {
    UNMODIFIED,
    UINT_256,
    UINT_32,
    UINT_64,
    ADDRESS,
    STRING,
    BOOL,
    UINT_16,
    UINT_8
}

struct State {
    mapping(string => address) updatedContracts;
    mapping(string => EnvironmentVariableType) updatedTypes;
    mapping(string => string) updatedStrings;
    mapping(string => address) updatedAddresses;
    mapping(string => uint256) updatedUInt256s;
    mapping(string => uint64) updatedUInt64s;
    mapping(string => uint32) updatedUInt32s;
    mapping(string => uint16) updatedUInt16s;
    mapping(string => uint8) updatedUInt8s;
    mapping(string => bool) updatedBools;
}

library ZEnvHelpers {
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm internal constant vm = Vm(VM_ADDRESS);

    string internal constant DEPLOYED_PREFIX = "ZEUS_DEPLOYED_";
    string internal constant ENV_PREFIX = "ZEUS_ENV_";

    string internal constant IMPL_SUFFIX = "_Impl";
    string internal constant PROXY_SUFFIX = "_Proxy";

    bytes32 internal constant STATE_SLOT = keccak256("STATE_SLOT");

    function state() internal pure returns (State storage s) {
        bytes32 stateSlot = STATE_SLOT;
        assembly {
            s.slot := stateSlot
        }
    }

    /**
     * @notice Returns the address of a proxy contract based on the provided key, querying the envvars injected by Zeus.
     * @param name The key to look up the address for. Should be the contract name, e.g. `type(DelegationManager).name`
     * @return The address of the contract associated with the provided key. Reverts if envvar not found.
     */
    function deployedProxy(State storage s, string memory name) internal view returns (address) {
        string memory lookupKey = string.concat(name, PROXY_SUFFIX);

        if (s.updatedContracts[lookupKey] != address(0)) {
            return s.updatedContracts[lookupKey];
        }

        string memory envvar = string.concat(DEPLOYED_PREFIX, lookupKey);
        return vm.envAddress(envvar);
    }

    function deployedImpl(State storage s, string memory name) internal view returns (address) {
        string memory lookupKey = string.concat(name, IMPL_SUFFIX);

        if (s.updatedContracts[lookupKey] != address(0)) {
            return s.updatedContracts[lookupKey];
        }

        string memory envvar = string.concat(DEPLOYED_PREFIX, lookupKey);
        return vm.envAddress(envvar);
    }

    // ZEUS_DEPLOYED_ + name + _$INDEX
    function deployedInstance(State storage s, string memory name, uint256 idx) internal view returns (address) {
        string memory lookupKey = string.concat(name, "_", vm.toString(idx));

        if (s.updatedContracts[lookupKey] != address(0)) {
            return s.updatedContracts[lookupKey];
        }

        string memory envvar = string.concat(DEPLOYED_PREFIX, lookupKey);
        return vm.envAddress(envvar);
    }

    function deployedInstanceCount(State storage s, string memory name) internal view returns (uint256) {
        uint256 count = 0;
        do {
            string memory lookupKey = string.concat(name, "_", vm.toString(count));

            if (s.updatedContracts[lookupKey] != address(0)) {
                count++;
                continue;
            }

            string memory envvar = string.concat(DEPLOYED_PREFIX, lookupKey);
            address res = vm.envOr(envvar, address(0));
            if (res == address(0)) {
                // no address is set.
                return count;
            }

            count++;
        } while (true);

        return count;
    }

    /**
     * Returns an `address` set in the current environment. NOTE: If you deployed this contract with zeus, you want `deployedX` instead.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function envAddress(State storage s, string memory key) internal view returns (address) {
        if (s.updatedTypes[key] != EnvironmentVariableType.UNMODIFIED) {
            return s.updatedAddresses[key];
        }

        string memory envvar = string.concat(ENV_PREFIX, key);
        return vm.envAddress(envvar);
    }

    /**
     * Returns a uint256 set in the current environment.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function envU256(State storage s, string memory key) internal view returns (uint256) {
        if (s.updatedTypes[key] != EnvironmentVariableType.UNMODIFIED) {
            return s.updatedUInt256s[key];
        }

        string memory envvar = string.concat(ENV_PREFIX, key);
        return uint256(vm.envUint(envvar));
    }

    /**
     * Returns a uint64 set in the current environment.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function envU64(State storage s, string memory key) internal view returns (uint64) {
        if (s.updatedTypes[key] != EnvironmentVariableType.UNMODIFIED) {
            return s.updatedUInt64s[key];
        }

        string memory envvar = string.concat(ENV_PREFIX, key);
        return uint64(vm.envUint(envvar));
    }

    /**
     * Returns a uint32 set in the current environment.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function envU32(State storage s, string memory key) internal view returns (uint32) {
        if (s.updatedTypes[key] != EnvironmentVariableType.UNMODIFIED) {
            return s.updatedUInt32s[key];
        }

        string memory envvar = string.concat(ENV_PREFIX, key);
        return uint32(vm.envUint(envvar));
    }

    /**
     * Returns a uint16 set in the current environment.
     * @param key The environment key. Corresponds to a ZEUS_* env variable.
     */
    function envU16(State storage s, string memory key) internal view returns (uint16) {
        if (s.updatedTypes[key] != EnvironmentVariableType.UNMODIFIED) {
            return s.updatedUInt16s[key];
        }

        string memory envvar = string.concat(ENV_PREFIX, key);
        return uint16(vm.envUint(envvar));
    }
}
