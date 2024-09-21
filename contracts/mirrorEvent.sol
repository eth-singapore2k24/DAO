// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract mirrorEvent {
    event newCID(string _cid);

    // emits the event containing the new CID from the IPFS
    function emitCID(string memory _cid) public {
        emit newCID(_cid);
    }
}