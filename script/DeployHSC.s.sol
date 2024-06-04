// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {HadesStableCoin} from "../src/HadesStableCoin.sol";

contract DeployHSC is Script {
    function run() external returns (HadesStableCoin) {
        vm.startBroadcast();
        HadesStableCoin hadesStableCoin = new HadesStableCoin();
        vm.stopBroadcast();
        return hadesStableCoin;
    }
}
