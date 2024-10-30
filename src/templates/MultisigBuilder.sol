// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import {ZeusScript} from "../utils/ZeusScript.sol";
import {MultisigCall, MultisigCallUtils} from "../utils/MultisigCallUtils.sol";
import {SafeTx, EncGnosisSafe} from "../utils/SafeTxUtils.sol";

/**
 * @title MultisigBuilder
 * @dev Abstract contract for building arbitrary multisig scripts.
 */
abstract contract MultisigBuilder is ZeusScript {
    using MultisigCallUtils for MultisigCall[];

    string internal constant multiSendCallOnlyName = "MultiSendCallOnly";

    /**
     * @notice Constructs a SafeTx object for a Gnosis Safe to ingest.
     * @return A SafeTx struct containing the transaction data to post to the Safe API.
     */
    function execute() public returns (SafeTx memory) {
        // get calls for Multisig from inheriting script
        MultisigCall[] memory calls = _execute();

        // encode calls as MultiSend data
        bytes memory data = calls.encodeMultisendTxs();

        // creates and return SafeTx object
        // assumes 0 value (ETH) being sent to multisig

        address multiSendCallOnly = zeusAddress(multiSendCallOnlyName);

        return SafeTx({to: multiSendCallOnly, value: 0, data: data, op: EncGnosisSafe.Operation.DelegateCall});
    }

    /**
     * @notice To be implemented by inheriting contract.
     * @return An array of MultisigCall objects.
     */
    function _execute() internal virtual returns (MultisigCall[] memory);
}
