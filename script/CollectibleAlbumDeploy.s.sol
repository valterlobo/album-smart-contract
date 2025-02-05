// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "../src/CollectibleAlbum.sol";

contract CollectibleAlbumDeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address initialOwner = vm.envAddress("OWNER");

        CollectibleAlbum collectibleAlbum =
            new CollectibleAlbum("CARD STAR WARS", "NFTSWAR", "https://pt.wikipedia.org/wiki/Star_Wars", initialOwner, 10);
        console.log(address(collectibleAlbum));
        vm.stopBroadcast();
    }
}
