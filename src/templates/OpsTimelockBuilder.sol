// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {Addresses, Environment, Params, ConfigParser} from "../utils/ConfigParser.sol";
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
     * @param addrs A struct containing environment addresses.
     * @param env A struct containing environment configuration values.
     * @param params A struct containing environment parameters.
     * @return A MultisigCall array representing the SafeTx object for the Gnosis Safe to process.
     */
    function _execute(Addresses memory addrs, Environment memory env, Params memory params)
        internal
        override
        returns (MultisigCall[] memory)
    {
        // get the queue data
        MultisigCall[] memory calls = queue(addrs, env, params);

        // encode calls for executor
        bytes memory executorCalldata = makeExecutorCalldata(calls, params.multiSendCallOnly, addrs.timelock);

        // encode executor data for timelock
        bytes memory timelockCalldata = abi.encodeWithSelector(
            ITimelock.queueTransaction.selector, addrs.executorMultisig, 0, "", executorCalldata, type(uint256).max
        );

        _opsCalls.append(addrs.timelock, timelockCalldata);

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
     * @param addrs A struct containing environment addresses.
     * @param env A struct containing environment configuration values.
     * @param params A struct containing environment parameters.
     * @return An array of MultisigCall structs representing the operations to queue.
     */
    function queue(Addresses memory addrs, Environment memory env, Params memory params)
        public
        virtual
        returns (MultisigCall[] memory);
}
