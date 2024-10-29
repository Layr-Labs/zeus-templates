// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {MultisigCall, MultisigCallUtils} from "../utils/MultisigCallUtils.sol";
import {SafeTx, SafeTxUtils, EncGnosisSafe} from "../utils/SafeTxUtils.sol";

import {MultisigBuilder} from "./MultisigBuilder.sol";

import {ITimelock} from "../interfaces/ITimelock.sol";

/**
 * @title OpsTimelockBuilder
 * @notice Template for an OpsMultisig script that goes through the timelock.
 * @dev Writing a script is done from the perspective of the OpsMultisig.
 */
abstract contract OpsTimelockBuilder is MultisigBuilder {
    using MultisigCallUtils for MultisigCall[];
    using SafeTxUtils for SafeTx;

    MultisigCall[] private _opsCalls;

    /**
     * @notice Overrides the parent _execute() function to call queue() and prepare transactions for the Timelock.
     * @return A MultisigCall array representing the SafeTx object for the Gnosis Safe to process.
     */
    function _execute() internal override returns (MultisigCall[] memory) {
        // get the queue data
        MultisigCall[] memory calls = queue();

        address multiSendCallOnly = vm.envAddress("ZEUS_DEPLOYED_MultiSendCallOnly");

        address timelock = vm.envAddress("ZEUS_DEPLOYED_Timelock");

        // encode calls for executor
        bytes memory executorCalldata = makeExecutorCalldata(calls, multiSendCallOnly, timelock);

        address executorMultisig = vm.envAddress("ZEUS_DEPLOYED_ExecutorMultisig");

        // encode executor data for timelock
        bytes memory timelockCalldata = abi.encodeWithSelector(
            ITimelock.queueTransaction.selector, executorMultisig, 0, "", executorCalldata, type(uint256).max
        );

        _opsCalls.append(timelock, timelockCalldata);

        // encode timelock data for ops multisig
        return _opsCalls;
    }

    /**
     * @notice Helper function to create calldata for executor.
     * This function can be used for queue or execute operations.
     * @param calls An array of MultisigCall structs representing the calls to be made.
     * @param multiSendCallOnly The address of the multiSendCallOnly contract.
     * @param timelock The address of the timelock contract.
     * @return A bytes array representing the calldata for the executor to be sent to the Timelock.
     */
    function makeExecutorCalldata(MultisigCall[] memory calls, address multiSendCallOnly, address timelock)
        public
        pure
        returns (bytes memory)
    {
        bytes memory data = calls.encodeMultisendTxs();

        bytes memory executorCalldata = SafeTx({
            to: multiSendCallOnly,
            value: 0,
            data: data,
            op: EncGnosisSafe.Operation.DelegateCall
        }).encodeForExecutor(timelock);

        return executorCalldata;
    }

    /**
     * @notice Queues a set of operations to be executed later.
     * @dev This abstract function is to be overridden by the inheriting contract, where calls are written from the POV of the Executor Multisig.
     * @return An array of MultisigCall structs representing the operations to queue.
     */
    function queue() public virtual returns (MultisigCall[] memory);
}
