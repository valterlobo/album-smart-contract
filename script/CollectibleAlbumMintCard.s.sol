// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "../src/CollectibleAlbum.sol";
import "../src/DataType.sol";

contract CollectibleAlbumMintCardScript is Script {
    function setUp() public {}

    function run() public {
        uint256 ownerPrivateKey = vm.envUint("OWNER_PK");
        vm.startBroadcast(ownerPrivateKey);
        address cardContract = vm.envAddress("MINT_CONTRACT");
        CollectibleAlbum albumCard = CollectibleAlbum(payable(cardContract));
        console.log(address(albumCard));
        albumCard.addCardType(
            1,
            10,
            RarityType.COMMON,
            "C-3PO | R2-D2",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/1.json"
        );
        albumCard.addCardType(
            2,
            10,
            RarityType.EPIC,
            "Chewbacca",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/2.json"
        );
        albumCard.addCardType(
            3,
            10,
            RarityType.LEGENDARY,
            "Darth Vader",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/3.json"
        );
        albumCard.addCardType(
            4,
            10,
            RarityType.RARE,
            "Kylo Ren",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/4.json"
        );
        albumCard.addCardType(
            5,
            10,
            RarityType.EPIC,
            "Leia Organa",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/5.json"
        );
        albumCard.addCardType(
            6,
            10,
            RarityType.LEGENDARY,
            "Luke Skywalker",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/6.json"
        );
        albumCard.addCardType(
            7, 10, RarityType.RARE, "Rey", "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/7.json"
        );
        albumCard.addCardType(
            8,
            10,
            RarityType.LEGENDARY,
            "Yoda",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/8.json"
        );
        albumCard.addCardType(
            9,
            10,
            RarityType.COMMON,
            "Stormtroopers",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/9.json"
        );
        albumCard.addCardType(
            10,
            10,
            RarityType.RARE,
            "Boba Fett",
            "ipfs://bafybeifu6wfhbf2wuaj2gsae5x4gxncgygqfqwb2znvcik4q66fh33k3yy/10.json"
        );

        //MINT
        albumCard.mintCardType(1, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(2, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(3, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(4, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(5, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(6, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(7, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(8, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(9, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        albumCard.mintCardType(10, address(0x3F9E5E96b26156541D369e57337881f6BA9Bc6A9), 5);
        vm.stopBroadcast();
    }
}
