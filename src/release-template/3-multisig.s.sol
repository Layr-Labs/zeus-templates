// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {MultisigCall, MultisigCallUtils, MultisigBuilder} from "../templates/MultisigBuilder.sol";
import {SafeTx, SafeTxUtils} from "../utils/SafeTxUtils.sol";
import {ITimelock} from "../interfaces/ITimelock.sol";
import {Queue} from "./2-multisig.s.sol";

contract Execute is MultisigBuilder {
    using MultisigCallUtils for MultisigCall[];
    using SafeTxUtils for SafeTx;

    MultisigCall[] internal _opsCalls;

    function _execute() internal override returns (MultisigCall[] memory) {
        Queue queue = new Queue();

        MultisigCall[] memory _executorCalls = queue.queue();

        address multiSendCallOnly = vm.envAddress("ZEUS_DEPLOYED_MultiSendCallOnly");

        address timelock = vm.envAddress("ZEUS_DEPLOYED_Timelock");

        bytes memory executorCalldata = queue.makeExecutorCalldata(_executorCalls, multiSendCallOnly, timelock);

        // execute queued transaction
        _opsCalls.append({
            to: timelock,
            value: 0,
            data: abi.encodeWithSelector(ITimelock.executeTransaction.selector, executorCalldata)
        });

        //////////////////////////
        // add more opsCalls here
        //////////////////////////

        return _opsCalls;
    }
}
