// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {MultisigCall, MultisigCallUtils, OpsTimelockBuilder} from "../templates/OpsTimelockBuilder.sol";

contract Queue is OpsTimelockBuilder {
    using MultisigCallUtils for MultisigCall[];

    MultisigCall[] internal _executorCalls;

    function queue() public override returns (MultisigCall[] memory) {
        //////////////////////////
        // construct executor data here
        //////////////////////////

        return _executorCalls;
    }
}
