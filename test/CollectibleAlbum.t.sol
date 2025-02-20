// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import "../src/CollectibleAlbum.sol";
import "../src/DataType.sol";
import "../src/ICollectiblesType.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CollectibleAlbumTest is Test {
    CollectibleAlbum collectibleAlbum;
    address owner = address(0x1);
    address operator = address(0x2);
    address user = address(0x3);

    uint256 MAX_INT = 2 ** 256 - 1;

    function setUp() public {
        vm.startPrank(owner);
        collectibleAlbum = new CollectibleAlbum("NFT Album", "NFTALB", "ipfs://album-uri", owner, 100);
        collectibleAlbum.transferOperator(operator);

        // Adiciona alguns CardTypes para teste

        // CardType id=1: Disponível (supply 10, maxSupply 100)
        collectibleAlbum.addCardType(10, 100, RarityType.COMMON, "Common Card", "ipfs://common");
        collectibleAlbum.setCardTypeSupply(10, 10);
        // CardType id=2: Disponível (supply 0, maxSupply 100)
        collectibleAlbum.addCardType(20, 100, RarityType.RARE, "Rare Card", "ipfs://rare");
        collectibleAlbum.setCardTypeSupply(20, 0);
        // CardType id=3: Disponível (supply 50, maxSupply 100)
        collectibleAlbum.addCardType(30, 100, RarityType.LEGENDARY, "Legendary Card", "ipfs://legendary");
        collectibleAlbum.setCardTypeSupply(30, 50);
        // CardType id=4: Totalmente mintado (supply == maxSupply)
        collectibleAlbum.addCardType(40, 100, RarityType.COMMON, "Fully Minted Card", "ipfs://minted");
        collectibleAlbum.setCardTypeSupply(40, 100);
        vm.stopPrank();
    }

    function testInitialValues() public view {
        assertEq(collectibleAlbum.name(), "NFT Album");
        assertEq(collectibleAlbum.symbol(), "NFTALB");
        assertEq(collectibleAlbum.getCollectiblesURI(), "ipfs://album-uri");
        assertEq(collectibleAlbum.getOperator(), operator);
    }

    function testAddCardType() public {
        vm.startPrank(owner);
        collectibleAlbum.addCardType(1, 100, RarityType.COMMON, "Card 1", "ipfs://card1");
        CardType memory card = collectibleAlbum.getCardType(1);

        assertEq(card.name, "Card 1");
        assertEq(card.uri, "ipfs://card1");
        assertEq(card.id, 1);
        assertEq(card.maxSupply, 100);
        assertEq(card.supply, 0);
        assertEq(uint256(card.rarityType), uint256(RarityType.COMMON));
    }

    /*
    function testFailAddCardTypeByNonOwner() public {
        vm.prank(user);
        vm.expectRevert("Incorrec XXXXXXXXXXX");
        collectibleAlbum.addCardType(2, 50, RarityType.RARE, "Card 2", "ipfs://card2");
    }*/

    function testSetCardURI() public {
        vm.startPrank(owner);
        collectibleAlbum.addCardType(1, 100, RarityType.COMMON, "Card 1", "ipfs://card1");
        collectibleAlbum.setCardURI(1, "ipfs://newcard1");

        CardType memory card = collectibleAlbum.getCardType(1);
        assertEq(card.uri, "ipfs://newcard1");
    }

    function test_Revert_SetCardURIByNonOwner() public {
        vm.startPrank(owner);
        collectibleAlbum.addCardType(1, 100, RarityType.COMMON, "Card 1", "ipfs://card1");
        vm.stopPrank();
        vm.prank(user);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(user)));
        collectibleAlbum.setCardURI(1, "ipfs://hacked-card");
    }

    function testMintCardType() public {
        vm.startPrank(owner);
        collectibleAlbum.addCardType(1, 100, RarityType.COMMON, "Card 1", "ipfs://card1");

        vm.startPrank(operator);
        vm.expectEmit();
        emit ICollectiblesType.MintCardType(1, user, 5);
        collectibleAlbum.mintCardType(1, user, 5);

        CardType memory card = collectibleAlbum.getCardType(1);

        assertEq(card.name, "Card 1");
        assertEq(card.supply, 5);
        console.log(card.supply);
    }

    function test_Revert_AddCardTypeWithDuplicateID() public {
        vm.startPrank(owner);
        // Adiciona o primeiro card com ID 1
        collectibleAlbum.addCardType(1, 100, RarityType.COMMON, "Card 1", "ipfs://card1");

        // Tenta adicionar outro card com o mesmo ID (deve falhar)
        vm.expectRevert("This CardType EXIST [ID]");
        collectibleAlbum.addCardType(1, 200, RarityType.RARE, "Card 2", "ipfs://card2");
    }

    function test_Revert_AddCardTypeWithSameMaxSupplyAndQuantity() public {
        vm.startPrank(owner);
        // Tenta adicionar um card onde maxSupply NÃO é igual a quantity (deve falhar)
        vm.expectRevert("maxSupply can be equal to initial quantity");
        collectibleAlbum.addCardType(2, 50, RarityType.RARE, "Card 2", "ipfs://card2");
    }

    function test_Revert_MintCardTypeByNonOperator() public {
        vm.prank(user);
        vm.expectRevert("Operator UNAUTHORIZED");
        collectibleAlbum.mintCardType(1, user, 5);
    }

    function test_Fail_Revert_MintingAmountExceedsTheMaximumSupplyLimit() public {
        vm.startPrank(owner);

        // Adiciona um novo CardType com maxSupply = 100 e supply inicial = 10
        collectibleAlbum.addCardType(3, 100, RarityType.LEGENDARY, "Card 3", "ipfs://card3");

        vm.stopPrank();
        vm.startPrank(operator);

        // Tenta mintar 95 unidades (total ficaria 10 + 95 = 105, ultrapassando maxSupply 100)
        vm.expectRevert("Minting amount exceeds the maximum supply limit");
        collectibleAlbum.mintCardType(3, user, 105);
    }

    function testTransferOperator() public {
        vm.startPrank(owner);
        collectibleAlbum.transferOperator(user);
        assertEq(collectibleAlbum.getOperator(), user);
    }

    function testTransferOwner() public {
        vm.startPrank(owner);
        collectibleAlbum.transferOwner(user);
        assertEq(collectibleAlbum.owner(), user);
    }

    /// @dev Valida se o método retorna o número correto de CardTypes solicitados.
    function testGetRandomAvailableCardTypesReturnsCorrectCount() public {
        uint256 requestedCount = 2;
        CardType[] memory pack = collectibleAlbum.getRandomAvailableCardTypes(requestedCount);
        assertEq(pack.length, requestedCount, "Pack length should equal requested count");
    }

    /// @dev Garante que CardTypes totalmente mintados (supply == maxSupply) não sejam retornados.
    function testGetRandomAvailableCardTypesExcludesFullyMinted() public {
        // Há 3 CardTypes disponíveis (ids 1,2 e 3); o id 4 está totalmente mintado.
        CardType[] memory pack = collectibleAlbum.getRandomAvailableCardTypes(3);
        for (uint256 i = 0; i < pack.length; i++) {
            assertTrue(pack[i].id != 4, "Pack should not include fully minted card type (id 4)");
        }
    }

    /// @dev Verifica se o método reverte ao solicitar mais CardTypes do que os disponíveis.
    function testRevertWhenNotEnoughAvailable() public {
        // Apenas 3 CardTypes disponíveis, logo solicitar 4 deve reverter.
        vm.expectRevert("Not enough available card types");
        CardType[] memory cardTypes = collectibleAlbum.getRandomAvailableCardTypes(4);

        console.log("/RANDOM");
        for (uint256 i = 0; i < cardTypes.length; i++) {
            console.log(cardTypes[i].id);
            console.log(cardTypes[i].name);
            console.log(cardTypes[i].supply);
            console.log("--------");
        }
        console.log("/RANDOM");
    }

    /* @dev Testa se duas chamadas sequenciais (com warp de tempo) retornam resultados diferentes.
    
    function testRandomPacksDiffer(uint256 time1, uint256 time2) public {
        vm.assume(
            (time1!=time2) && MAX_INT > (block.timestamp + time1) && MAX_INT > (block.timestamp + time2)
        );

        // Warp para alterar o block.timestamp e obter sementes diferentes
        vm.warp(block.timestamp + time1);
        CardType[] memory pack1 = collectibleAlbum.getRandomAvailableCardTypes(2);

        collectibleAlbum.getRandomAvailableCardTypes(2);
        collectibleAlbum.getRandomAvailableCardTypes(2);
        collectibleAlbum.getRandomAvailableCardTypes(2);
        collectibleAlbum.getRandomAvailableCardTypes(2);
        collectibleAlbum.getRandomAvailableCardTypes(2);

        vm.warp(block.timestamp + time2);
        CardType[] memory pack2 = collectibleAlbum.getRandomAvailableCardTypes(2);

        bool isDifferent = false;
        // Verifica se pelo menos um CardType difere entre os dois packs
        for (uint256 i = 0; i < pack1.length; i++) {
            console.log("--------");
            console.log(pack1[i].id);
            console.log("<>");
            console.log(pack2[i].id);
            console.log(pack1[i].name);
            console.log(pack1[i].supply);
            console.log("--------");
            if (pack1[i].id != pack2[i].id) {
                isDifferent = true;
                break;
            }
        }
        assertTrue(isDifferent, "Sequential packs should not be identical");
    }*/
}
