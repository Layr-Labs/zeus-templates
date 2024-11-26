// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {ZeusScript} from "../utils/ZeusScript.sol";
import {MultisigCall, MultisigCallUtils} from "../utils/MultisigCallUtils.sol";
import {SafeTx, EncGnosisSafe} from "../utils/SafeTxUtils.sol";
import {console} from "forge-std/console.sol";

/**
 * @title MultisigBuilder
 * @dev Abstract contract for building arbitrary multisig scripts.
 */
abstract contract MultisigBuilder is ZeusScript {
    using MultisigCallUtils for MultisigCall[];

    string internal constant multiSendCallOnlyName = "MultiSendCallOnly";

    /**
     * @notice Constructs a SafeTx object for a Gnosis Safe to ingest. Emits via `ZeusMultisigExecute`
     */
    function execute() public {
        address multisigContext = getMultisigContext();
        vm.startPrank(multisigContext);
        console.log("- establishing multisig spoof");
        console.log(multisigContext);
        _runAsMultisig();
        vm.stopPrank();
    }

    /**
     * @notice To be implemented by inheriting contract.
     *
     * This function will be pranked from the perspective of the multisig you choose to run with.
     * DO NOT USE vm.startPrank()/stopPrank() during your implementation.
     */
    function _runAsMultisig() internal virtual;
}
