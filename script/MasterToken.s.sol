// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MasterToken} from "../src/MasterToken.sol";

contract TokenScript is Script {
    MasterToken public token;

    function run() public {
        vm.startBroadcast();

        token = new MasterToken("MasterToken", "MTK");

        vm.stopBroadcast();
    }
}
