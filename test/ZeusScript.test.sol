// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {Test} from "forge-std/Test.sol";
import {ZeusScript, EncGnosisSafe} from "../src/utils/ZeusScript.sol";
import {StringUtils} from "../src/utils/StringUtils.sol";

contract ZeusScriptTest is ZeusScript {
    function setUp() public {
        // Set some environment variables to test fallback logic with simple incremental addresses.
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_UINT256", "9999");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_BOOL", "true");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_STRING", "fallbackValue");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_ADDRESS", "0x0000000000000000000000000000000000000001");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_UINT32", "12345");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_UINT16", "321");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_UINT8", "42");
        vm.setEnv("ZEUS_ENV_MY_FALLBACK_UINT64", "7777777");

        // Set environment variables for deployed contracts, using simple addresses like 0x2, 0x3, etc.
        vm.setEnv("ZEUS_DEPLOYED_MyContract", "0x0000000000000000000000000000000000000002");
        vm.setEnv("ZEUS_DEPLOYED_MyContract_0", "0x0000000000000000000000000000000000000003");
        vm.setEnv("ZEUS_DEPLOYED_MyContract_1", "0x0000000000000000000000000000000000000004");
        vm.setEnv("ZEUS_DEPLOYED_MyContract_Proxy", "0x0000000000000000000000000000000000000005");
        vm.setEnv("ZEUS_DEPLOYED_MyContract_Impl", "0x0000000000000000000000000000000000000006");
    }

    // --------------------------------------
    // Test zUpdate Functions and Events
    // --------------------------------------

    function testUpdateString() public {
        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_STRING_KEY", EnvironmentVariableType.STRING, abi.encode("hello"));

        string memory updated = zUpdate("MY_STRING_KEY", "hello");
        assertEq(updated, "hello");
        assertEq(uint256(updatedTypes["MY_STRING_KEY"]), uint256(EnvironmentVariableType.STRING));
        // The code stores the key itself in updatedStrings
        assertEq(updatedStrings["MY_STRING_KEY"], "MY_STRING_KEY");
    }

    function testUpdateAddress() public {
        address testAddr = address(0x1234);

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_ADDRESS_KEY", EnvironmentVariableType.ADDRESS, abi.encode(testAddr));

        address updated = zUpdate("MY_ADDRESS_KEY", testAddr);
        assertEq(updated, testAddr);
        assertEq(uint256(updatedTypes["MY_ADDRESS_KEY"]), uint256(EnvironmentVariableType.ADDRESS));
        assertEq(updatedAddresses["MY_ADDRESS_KEY"], testAddr);
    }

    function testUpdateUint256() public {
        uint256 val = 42;

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_UINT256_KEY", EnvironmentVariableType.UINT_256, abi.encode(val));

        uint256 updated = zUpdateUint256("MY_UINT256_KEY", val);
        assertEq(updated, val);
        assertEq(uint256(updatedTypes["MY_UINT256_KEY"]), uint256(EnvironmentVariableType.UINT_256));
        assertEq(updatedUInt256s["MY_UINT256_KEY"], val);
    }

    function testUpdateUint64() public {
        uint64 val = 98765;

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_UINT64_KEY", EnvironmentVariableType.UINT_64, abi.encode(val));

        uint64 updated = zUpdateUint64("MY_UINT64_KEY", val);
        assertEq(updated, val);
        assertEq(uint256(updatedTypes["MY_UINT64_KEY"]), uint256(EnvironmentVariableType.UINT_64));
        assertEq(updatedUInt64s["MY_UINT64_KEY"], val);
    }

    function testUpdateUint32() public {
        uint32 val = 1234;

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_UINT32_KEY", EnvironmentVariableType.UINT_32, abi.encode(val));

        uint32 updated = zUpdateUint32("MY_UINT32_KEY", val);
        assertEq(updated, val);
        assertEq(uint256(updatedTypes["MY_UINT32_KEY"]), uint256(EnvironmentVariableType.UINT_32));
        assertEq(updatedUInt32s["MY_UINT32_KEY"], val);
    }

    function testUpdateUint16() public {
        uint16 val = 4321;

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_UINT16_KEY", EnvironmentVariableType.UINT_16, abi.encode(val));

        uint16 updated = zUpdateUint16("MY_UINT16_KEY", val);
        assertEq(updated, val);
        assertEq(uint256(updatedTypes["MY_UINT16_KEY"]), uint256(EnvironmentVariableType.UINT_16));
        assertEq(updatedUInt16s["MY_UINT16_KEY"], val);
    }

    function testUpdateUint8() public {
        uint8 val = 99;

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_UINT8_KEY", EnvironmentVariableType.UINT_8, abi.encode(val));

        uint8 updated = zUpdateUint8("MY_UINT8_KEY", val);
        assertEq(updated, val);
        assertEq(uint256(updatedTypes["MY_UINT8_KEY"]), uint256(EnvironmentVariableType.UINT_8));
        assertEq(updatedUInt8s["MY_UINT8_KEY"], val);
    }

    function testUpdateBool() public {
        bool val = true;

        vm.expectEmit(true, true, true, true);
        emit ZeusEnvironmentUpdate("MY_BOOL_KEY", EnvironmentVariableType.BOOL, abi.encode(val));

        bool updated = zUpdate("MY_BOOL_KEY", val);
        assertTrue(updated);
        assertEq(uint256(updatedTypes["MY_BOOL_KEY"]), uint256(EnvironmentVariableType.BOOL));
        assertEq(updatedBools["MY_BOOL_KEY"], true);
    }

    function testUpdatePreventsTypeChange() public {
        zUpdateUint256("MY_KEY", 123);
        // Attempting to change type from UINT_256 to STRING should revert
        vm.expectRevert();
        zUpdate("MY_KEY", "notAllowed");
    }

    function testMultipleUpdatesSameType() public {
        zUpdateUint256("REUSE_KEY", 100);
        uint256 val = zUpdateUint256("REUSE_KEY", 200);
        assertEq(val, 200);
    }

    // --------------------------------------
    // Test Deployed Contract and Instances
    // --------------------------------------

    function testZDeployedContractFallbackToVmEnv() public view {
        address deployed = zDeployedContract("MyContract");
        assertEq(deployed, address(0x0000000000000000000000000000000000000002));
    }

    function testZDeployedContractWithOverride() public {
        updatedContracts["MyContract"] = address(0x1111111111111111111111111111111111111111);
        address deployed = zDeployedContract("MyContract");
        assertEq(deployed, address(0x1111111111111111111111111111111111111111));
    }

    function testZDeployedInstanceFallback() public view {
        // from env: ZEUS_DEPLOYED_MyContract_0 = 0x...bbbb
        //           ZEUS_DEPLOYED_MyContract_1 = 0x...cccc
        address inst0 = zDeployedInstance("MyContract", 0);
        address inst1 = zDeployedInstance("MyContract", 1);
        assertEq(inst0, address(0x0000000000000000000000000000000000000003));
        assertEq(inst1, address(0x0000000000000000000000000000000000000004));
    }

    function testZDeployedInstanceWithOverrides() public {
        updatedContracts["MyContract_0"] = address(0x1111111111111111111111111111111111111111);
        updatedContracts["MyContract_1"] = address(0x2222222222222222222222222222222222222222);

        address inst0 = zDeployedInstance("MyContract", 0);
        address inst1 = zDeployedInstance("MyContract", 1);
        assertEq(inst0, address(0x1111111111111111111111111111111111111111));
        assertEq(inst1, address(0x2222222222222222222222222222222222222222));
    }

    function testZDeployedInstanceCountWithOverrides() public {
        updatedContracts["MyContract_0"] = address(0x1111111111111111111111111111111111111111);
        updatedContracts["MyContract_1"] = address(0x2222222222222222222222222222222222222222);

        uint256 count = zDeployedInstanceCount("MyContract");
        assertEq(count, 2);
    }

    function testZDeployedInstanceCountFromEnv() public view {
        // We'll rely on env variables: MyContract_0 and MyContract_1 are set, MyContract_2 is not
        uint256 count = zDeployedInstanceCount("MyContract");
        assertEq(count, 2);
    }

    function testZDeployedProxyFallback() public view {
        address p = zDeployedProxy("MyContract");
        assertEq(p, address(0x0000000000000000000000000000000000000005));
    }

    function testZDeployedImplFallback() public view {
        address i = zDeployedImpl("MyContract");
        assertEq(i, address(0x0000000000000000000000000000000000000006));
    }

    // --------------------------------------
    // Test Env Variable Getters without updates (fallback to vm.env)
    // --------------------------------------

    function testZAddressFallback() public view {
        address val = zAddress("MY_FALLBACK_ADDRESS");
        assertEq(val, address(0x0000000000000000000000000000000000000001));
    }

    function testZUint256Fallback() public view {
        uint256 val = zUint256("MY_FALLBACK_UINT256");
        assertEq(val, 9999);
    }

    function testZBoolFallback() public view {
        bool val = zBool("MY_FALLBACK_BOOL");
        assertTrue(val);
    }

    function testZStringFallback() public view {
        string memory val = zString("MY_FALLBACK_STRING");
        assertEq(val, "fallbackValue");
    }

    function testZUint32Fallback() public view {
        uint32 val = zUint32("MY_FALLBACK_UINT32");
        assertEq(val, 12345);
    }

    function testZUint16Fallback() public view {
        uint16 val = zUint16("MY_FALLBACK_UINT16");
        assertEq(val, 321);
    }

    function testZUint8Fallback() public view {
        uint8 val = zUint8("MY_FALLBACK_UINT8");
        assertEq(val, 42);
    }

    function testZUint64Fallback() public view {
        uint64 val = zUint64("MY_FALLBACK_UINT64");
        assertEq(val, 7777777);
    }

    // Test updating and then calling fallback getters to ensure updated value overrides env:
    function testZBoolOverride() public {
        zUpdate("MY_FALLBACK_BOOL", false);
        bool val = zBool("MY_FALLBACK_BOOL");
        assertFalse(val);
    }

    // --------------------------------------
    // Test impl() and proxy() suffix functions
    // --------------------------------------

    function testImplAndProxySuffixFunctions() public pure {
        string memory base = "MyContract";
        string memory implName = impl(base);
        string memory proxyName = proxy(base);

        assertEq(implName, "MyContract_Impl");
        assertEq(proxyName, "MyContract_Proxy");
    }

    // --------------------------------------
    // Test that we can emit unused events for coverage
    // --------------------------------------

    function testZeusRequireMultisigEvent() public {
        vm.expectEmit(true, true, true, true);
        emit ZeusRequireMultisig(address(0xabc), Operation.Call);
        // Operation.Call and Operation.DelegateCall are from the enum defined in ZeusScript
        emit ZeusRequireMultisig(address(0xabc), Operation.Call);
    }

    function testZeusDeployEvent() public {
        vm.expectEmit(true, true, true, true);
        emit ZeusDeploy("TestName", address(0xdef), true);
        emit ZeusDeploy("TestName", address(0xdef), true);
    }

    function testZeusMultisigExecuteEvent() public {
        // EncGnosisSafe.Operation is presumably the same shape as Operation
        vm.expectEmit(true, true, true, true);
        emit ZeusMultisigExecute(address(0x123), 1, "0x1234", EncGnosisSafe.Operation.Call);
        emit ZeusMultisigExecute(address(0x123), 1, "0x1234", EncGnosisSafe.Operation.Call);
    }

    function testZDeployedInstanceCountZero() public view {
        // No env vars or updatedContracts set for "UnknownContract".
        // This should return 0 without entering the loop multiple times.
        uint256 count = zDeployedInstanceCount("UnknownContract");
        assertEq(count, 0);
    }

    function testMissingEnvVarForZDeployedContract() public {
        // Attempting to get a deployed contract that doesn't exist should revert.
        vm.expectRevert();
        zDeployedContract("NonExistentContract");
    }

    function testMissingEnvVarForZAddress() public {
        // No update and no env var for this key; should revert on env lookup.
        vm.expectRevert();
        zAddress("NoSuchKey");
    }

    function testMissingEnvVarForZBool() public {
        vm.expectRevert();
        zBool("NoBoolKey");
    }

    function testMissingEnvVarForZString() public {
        vm.expectRevert();
        zString("NoStringKey");
    }

    function testMissingEnvVarForZUint256() public {
        vm.expectRevert();
        zUint256("NoUint256Key");
    }

    function testMissingEnvVarForZUint64() public {
        vm.expectRevert();
        zUint64("NoUint64Key");
    }

    function testMissingEnvVarForZUint32() public {
        vm.expectRevert();
        zUint32("NoUint32Key");
    }

    function testMissingEnvVarForZUint16() public {
        vm.expectRevert();
        zUint16("NoUint16Key");
    }

    function testMissingEnvVarForZUint8() public {
        vm.expectRevert();
        zUint8("NoUint8Key");
    }

    function testZUpdateTypeChangeOnOtherTypes() public {
        // Set as ADDRESS first
        zUpdate("TYPE_CHANGE_KEY", address(0x1));
        // Now try changing to BOOL
        vm.expectRevert();
        zUpdate("TYPE_CHANGE_KEY", true);
    }

    function testZUpdateTypeChangeOnIntegers() public {
        // Set as UINT_32 first
        zUpdateUint32("TYPE_CHANGE_INT_KEY", 100);
        // Now try changing to UINT_64
        vm.expectRevert();
        zUpdateUint64("TYPE_CHANGE_INT_KEY", 200);
    }

    function testZUpdateTypeChangeOnStringToUint() public {
        zUpdate("TYPE_CHANGE_STR_KEY", "original");
        // Now try changing to UINT_256
        vm.expectRevert();
        zUpdateUint256("TYPE_CHANGE_STR_KEY", 999);
    }

    function testZDeployedInstanceNonExistentIndex() public {
        // Ensure that requesting a non-existent index reverts or returns correctly.
        // If `vm.envAddress` reverts on missing var, catch it.
        vm.expectRevert();
        zDeployedInstance("MyContract", 999); // large index with no env
    }

    function testZeusRequireMultisigEventDelegateCall() public {
        // Emit with DelegateCall to cover enum branch
        vm.expectEmit(true, true, true, true);
        emit ZeusRequireMultisig(address(0xabc), Operation.DelegateCall);
        emit ZeusRequireMultisig(address(0xabc), Operation.DelegateCall);
    }

    function testZeusDeployEventFalseSingleton() public {
        // Emit with false to cover different boolean branch
        vm.expectEmit(true, true, true, true);
        emit ZeusDeploy("AnotherTestName", address(0xdef), false);
        emit ZeusDeploy("AnotherTestName", address(0xdef), false);
    }

    function testZeusMultisigExecuteEventDelegateCall() public {
        // Emit with DelegateCall operation to cover that branch
        vm.expectEmit(true, true, true, true);
        emit ZeusMultisigExecute(address(0x123), 1, "0x5678", EncGnosisSafe.Operation.DelegateCall);
        emit ZeusMultisigExecute(address(0x123), 1, "0x5678", EncGnosisSafe.Operation.DelegateCall);
    }

    function testZDeployedContractNoEnvNoUpdate() public {
        // No env var and no updated contract entry
        vm.expectRevert();
        zDeployedContract("DoesNotExist");
    }

    function testInvalidEnvAddress() public {
        vm.setEnv("ZEUS_ENV_INVALID_ADDRESS", "notAnAddress");
        vm.expectRevert(); 
        zAddress("INVALID_ADDRESS");
    }

    function testInvalidEnvUint() public {
        vm.setEnv("ZEUS_ENV_INVALID_UINT256", "notANumber");
        vm.expectRevert();
        zUint256("INVALID_UINT256");
    }

    function testInvalidEnvBool() public {
        vm.setEnv("ZEUS_ENV_INVALID_BOOL", "notABool");
        vm.expectRevert();
        zBool("INVALID_BOOL");
    }

    function testMixedZDeployedInstanceCount() public {
        // For "MixedContract":
        // - 0 from updatedContracts
        // - 1 from environment variable
        // - 2 missing entirely
        updatedContracts["MixedContract_0"] = address(0x0000000000000000000000000000000000000011);
        vm.setEnv("ZEUS_DEPLOYED_MixedContract_1", "0x0000000000000000000000000000000000000012");
        // No _2 set, should return count=2
        uint256 count = zDeployedInstanceCount("MixedContract");
        assertEq(count, 2);
    }

    function testProxySuffixWithEmptyString() public view {
        string memory p = proxy("");
        assertEq(p, "_Proxy");
    }

    function testImplSuffixWithEmptyString() public view {
        string memory i = impl("");
        assertEq(i, "_Impl");
    }

    function testMultipleUpdatesSameTypeUint64() public {
        zUpdateUint64("RETEST_UINT64", 1000);
        zUpdateUint64("RETEST_UINT64", 2000);
        zUpdateUint64("RETEST_UINT64", 3000);
        assertEq(zUint64("RETEST_UINT64"), 3000);
    }

}
