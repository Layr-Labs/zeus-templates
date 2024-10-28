// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "forge-std/StdAssertions.sol";

import "./StringUtils.sol";

struct Environment {
    uint256 chainid;
    string name;
    string lastUpdated;
}

struct Params {
    // admin
    address multiSendCallOnly;
    // pods
    address ethPOS;
    uint64 EIGENPOD_GENESIS_TIME;
    // rewards
    uint32 CALCULATION_INTERVAL_SECONDS;
    uint32 MAX_REWARDS_DURATION;
    uint32 MAX_RETROACTIVE_LENGTH;
    uint32 MAX_FUTURE_LENGTH;
    uint32 GENESIS_REWARDS_TIMESTAMP;
    address REWARDS_UPDATER_ADDRESS;
    uint32 ACTIVATION_DELAY;
    uint16 GLOBAL_OPERATOR_COMMISSION_BIPS;
}

struct TUPInfo {
    address proxy;
    address impl;
    address pendingImpl;
}

struct BeaconInfo {
    address beacon;
    address impl;
    address pendingImpl;
}

struct TokenInfo {
    address proxy;
    address impl;
    address pendingImpl;
    address proxyAdmin;
}

struct Addresses {
    // admin
    address communityMultisig;
    address executorMultisig;
    address operationsMultisig;
    address pauserMultisig;
    address pauserRegistry;
    address proxyAdmin;
    address timelock;
    // core
    TUPInfo avsDirectory;
    TUPInfo delegationManager;
    TUPInfo rewardsCoordinator;
    TUPInfo slasher;
    TUPInfo strategyManager;
    // pods
    BeaconInfo eigenPod;
    TUPInfo eigenPodManager;
    TUPInfo delayedWithdrawalRouter;
    // strategies
    TUPInfo strategyFactory;
    BeaconInfo strategyBeacon;
    TUPInfo[] preLongtailStrats;
    // token
    TokenInfo EIGEN;
    TokenInfo bEIGEN;
    TUPInfo eigenStrategy;
}

contract ConfigParser is Script, StdAssertions {
    using StringUtils for *;

    string private _configPath;
    string private _configData;

    function _readConfigFile(string memory configPath)
        internal
        returns (Addresses memory, Environment memory, Params memory)
    {
        _configPath = configPath;
        _configData = vm.readFile(_configPath);
        emit log_named_string("Reading from config file", _configPath);

        Environment memory env = _readEnvironment();
        Params memory params = _readParams();
        Addresses memory addrs = _readAddresses();

        return (addrs, env, params);
    }

    /**
     *
     *                            READS
     *
     */
    function _readEnvironment() private returns (Environment memory) {
        return Environment({
            chainid: _readUint(".config.environment.chainid"),
            name: _readString(".config.environment.name"),
            lastUpdated: _readString(".config.environment.lastUpdated")
        });
    }

    function _readParams() private returns (Params memory) {
        return Params({
            multiSendCallOnly: _readAddress(".config.params.multiSendCallOnly"),
            ethPOS: _readAddress(".config.params.ethPOS"),
            EIGENPOD_GENESIS_TIME: uint64(_readUint(".config.params.EIGENPOD_GENESIS_TIME")),
            CALCULATION_INTERVAL_SECONDS: uint32(_readUint(".config.params.CALCULATION_INTERVAL_SECONDS")),
            MAX_REWARDS_DURATION: uint32(_readUint(".config.params.MAX_REWARDS_DURATION")),
            MAX_RETROACTIVE_LENGTH: uint32(_readUint(".config.params.MAX_RETROACTIVE_LENGTH")),
            MAX_FUTURE_LENGTH: uint32(_readUint(".config.params.MAX_FUTURE_LENGTH")),
            GENESIS_REWARDS_TIMESTAMP: uint32(_readUint(".config.params.GENESIS_REWARDS_TIMESTAMP")),
            REWARDS_UPDATER_ADDRESS: _readAddress(".config.params.REWARDS_UPDATER_ADDRESS"),
            ACTIVATION_DELAY: uint32(_readUint(".config.params.ACTIVATION_DELAY")),
            GLOBAL_OPERATOR_COMMISSION_BIPS: uint16(_readUint(".config.params.GLOBAL_OPERATOR_COMMISSION_BIPS"))
        });
    }

    function _readAddresses() private returns (Addresses memory) {
        return Addresses({
            // Admin
            communityMultisig: _readAddress(".deployment.admin.communityMultisig"),
            executorMultisig: _readAddress(".deployment.admin.executorMultisig"),
            operationsMultisig: _readAddress(".deployment.admin.operationsMultisig"),
            pauserMultisig: _readAddress(".deployment.admin.pauserMultisig"),
            pauserRegistry: _readAddress(".deployment.admin.pauserRegistry"),
            proxyAdmin: _readAddress(".deployment.admin.proxyAdmin"),
            timelock: _readAddress(".deployment.admin.timelock"),
            // Core
            avsDirectory: _readTUP(".deployment.core.avsDirectory"),
            delegationManager: _readTUP(".deployment.core.delegationManager"),
            rewardsCoordinator: _readTUP(".deployment.core.rewardsCoordinator"),
            slasher: _readTUP(".deployment.core.slasher"),
            strategyManager: _readTUP(".deployment.core.strategyManager"),
            // Pods
            eigenPod: _readBeacon(".deployment.pods.eigenPod"),
            eigenPodManager: _readTUP(".deployment.pods.eigenPodManager"),
            delayedWithdrawalRouter: _readTUP(".deployment.pods.delayedWithdrawalRouter"),
            // Strategies
            strategyFactory: _readTUP(".deployment.strategies.strategyFactory"),
            strategyBeacon: _readBeacon(".deployment.strategies.strategyBeacon"),
            preLongtailStrats: _readStrategies(".deployment.strategies.preLongtailStrats"),
            // Token
            EIGEN: _readToken(".deployment.token.EIGEN"),
            bEIGEN: _readToken(".deployment.token.bEIGEN"),
            eigenStrategy: _readTUP(".deployment.token.eigenStrategy")
        });
    }

    function _readTUP(string memory jsonLocation) private returns (TUPInfo memory) {
        return TUPInfo({
            proxy: _readAddress(jsonLocation.concat(".proxy")),
            impl: _readAddress(jsonLocation.concat(".impl")),
            pendingImpl: _readAddress(jsonLocation.concat(".pendingImpl"))
        });
    }

    function _readBeacon(string memory jsonLocation) private returns (BeaconInfo memory) {
        return BeaconInfo({
            beacon: _readAddress(jsonLocation.concat(".beacon")),
            impl: _readAddress(jsonLocation.concat(".impl")),
            pendingImpl: _readAddress(jsonLocation.concat(".pendingImpl"))
        });
    }

    function _readStrategies(string memory jsonLocation) private returns (TUPInfo[] memory) {
        address[] memory strategyProxies = stdJson.readAddressArray(_configData, jsonLocation.concat(".addrs"));
        address strategyImpl = _readAddress(jsonLocation.concat(".impl"));

        TUPInfo[] memory strategyInfos = new TUPInfo[](strategyProxies.length);

        for (uint256 i = 0; i < strategyInfos.length; i++) {
            strategyInfos[i] = TUPInfo({proxy: strategyProxies[i], impl: strategyImpl, pendingImpl: address(0)});
        }

        return strategyInfos;
    }

    function _readToken(string memory jsonLocation) private returns (TokenInfo memory) {
        return TokenInfo({
            proxy: _readAddress(jsonLocation.concat(".proxy")),
            impl: _readAddress(jsonLocation.concat(".impl")),
            pendingImpl: _readAddress(jsonLocation.concat(".pendingImpl")),
            proxyAdmin: _readAddress(jsonLocation.concat(".proxyAdmin"))
        });
    }

    function _readAddress(string memory jsonLocation) private returns (address) {
        return stdJson.readAddress(_configData, jsonLocation);
    }

    function _readUint(string memory jsonLocation) private returns (uint256) {
        return stdJson.readUint(_configData, jsonLocation);
    }

    function _readString(string memory jsonLocation) private returns (string memory) {
        return stdJson.readString(_configData, jsonLocation);
    }
}
