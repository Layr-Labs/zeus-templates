// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import "./ZEnvHelpers.sol";
import {StringUtils} from "./StringUtils.sol";
import {Script} from "forge-std/Script.sol";
import {EncGnosisSafe} from "./EncGnosisSafe.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

abstract contract ZeusScript is Script, Test {
    using StringUtils for string;
    using ZEnvHelpers for *;

    enum Operation {
        Call,
        DelegateCall
    }

    struct MultisigOptions {
        address addr; // the address of the multisig
        Operation callType; // call vs. delegateCall
    }

    event ZeusRequireMultisig(address addr, Operation callType);
    event ZeusEnvironmentUpdate(string key, EnvironmentVariableType internalType, bytes value);
    event ZeusDeploy(string name, address addr, bool singleton);
    event ZeusMultisigExecute(address to, uint256 value, bytes data, EncGnosisSafe.Operation op);

    enum Cleanliness {
        UNCHANGED, // this key has not been touched previously
        UPTODATE, // this key has been asserted since its last change
        DIRTY // this key has a pending unasserted change.

    }

    mapping(string => Cleanliness) internal _dirty; // 1 if dirty, else 0.
    string[] internal _modifiedKeys;

    function _markDirty(string memory key) private {
        if (_dirty[key] == Cleanliness.UNCHANGED) {
            _modifiedKeys.push(key);
        }
        _dirty[key] = Cleanliness.DIRTY;
    }

    function _clean(string memory key) private {
        require(_dirty[key] == Cleanliness.DIRTY, "Asserted key was unchanged.");
        _dirty[key] = Cleanliness.UPTODATE;
    }

    /**
     * Environment manipulation - update variables in the current environment's configuration *****
     */
    // NOTE: you do not need to use these for contract addresses, which are tracked and injected automatically.
    // NOTE: do not use `.update()` during a vm.broadcast() segment.
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function zUpdate(string memory key, string memory value) public returns (string memory) {        
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.STRING
        );
        state.updatedTypes[key] = EnvironmentVariableType.STRING;
        state.updatedStrings[key] = key;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.STRING, abi.encode(value));
        return value;
    }

    function zUpdate(string memory key, address value) public returns (address) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.ADDRESS
        );
        state.updatedTypes[key] = EnvironmentVariableType.ADDRESS;
        state.updatedAddresses[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.ADDRESS, abi.encode(value));
        return value;
    }

    function zUpdateUint256(string memory key, uint256 value) public returns (uint256) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.UINT_256
        );
        state.updatedTypes[key] = EnvironmentVariableType.UINT_256;
        state.updatedUInt256s[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.UINT_256, abi.encode(value));
        return value;
    }

    function zUpdateUint64(string memory key, uint64 value) public returns (uint64) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.UINT_64
        );
        state.updatedTypes[key] = EnvironmentVariableType.UINT_64;
        state.updatedUInt64s[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.UINT_64, abi.encode(value));
        return value;
    }

    function zUpdateUint32(string memory key, uint32 value) public returns (uint32) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.UINT_32
        );
        state.updatedTypes[key] = EnvironmentVariableType.UINT_32;
        state.updatedUInt32s[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.UINT_32, abi.encode(value));
        return value;
    }

    function zUpdateUint16(string memory key, uint16 value) public returns (uint16) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.UINT_16
        );
        state.updatedTypes[key] = EnvironmentVariableType.UINT_16;
        state.updatedUInt16s[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.UINT_16, abi.encode(value));
        return value;
    }

    function zUpdateUint8(string memory key, uint8 value) public returns (uint8) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED
                || state.updatedTypes[key] == EnvironmentVariableType.UINT_8
        );
        state.updatedTypes[key] = EnvironmentVariableType.UINT_8;
        state.updatedUInt8s[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.UINT_8, abi.encode(value));
        return value;
    }

    function zUpdate(string memory key, bool value) public returns (bool) {
        State storage state = ZEnvHelpers.state();
        
        require(
            state.updatedTypes[key] == EnvironmentVariableType.UNMODIFIED 
                || state.updatedTypes[key] == EnvironmentVariableType.BOOL
        );
        state.updatedTypes[key] = EnvironmentVariableType.BOOL;
        state.updatedBools[key] = value;
        emit ZeusEnvironmentUpdate(key, EnvironmentVariableType.BOOL, abi.encode(value));
        return value;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function zAssertDeployed(string[] memory contractNames) public {
        zAssertTest();
        for (uint256 i = 0; i < contractNames.length; i++) {
            _clean(contractNames[i]);
        }
    }

    function zAssertUpdated(string[] memory environmentParameters) public {
        zAssertTest();
        for (uint256 i = 0; i < environmentParameters.length; i++) {
            _clean(environmentParameters[i]);
        }
    }

    function zAssertClean() public {
        zAssertTest();

        for (uint256 i = 0; i < _modifiedKeys.length; i++) {
            string memory message = string.concat(_modifiedKeys[i], ": key was not asserted");
            require(uint256(_dirty[_modifiedKeys[i]]) == uint256(Cleanliness.UPTODATE), message);
        }

        delete _modifiedKeys;
    }

    function zAssertTest() public view {
        require(vm.envBool("ZEUS_TEST"), "not a zeus test");
    }
}
