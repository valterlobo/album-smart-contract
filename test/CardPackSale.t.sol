// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/CardPackSale.sol"; // Certifique-se de ajustar o caminho se necessário
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../src/DataType.sol";
import "../src/ICollectiblesType.sol";
import "../src/CollectibleAlbum.sol";

/**
 * @dev Contrato USDC mock para testes, implementando as funções básicas de um ERC20.
 */
contract MockERC20 is IERC20 {
    string public name = "Mock USDC";
    string public symbol = "USDC";
    uint8 public decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        return true;
    }

    // Função para mintar tokens para os testes
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}

/**
 * @dev Testes para o contrato CardPackSale.
 */
contract CardPackSaleTest is Test {
    MockERC20 usdc;
    ICollectiblesType album;
    CardPackSale sale;

    // Endereços para o tesouro e para o comprador
    address treasury = address(0x999);
    address buyer = address(0x123);
    address owner = address(0x124);

    // Preço do card pack e quantidade de cards por pack
    uint256 cardPackPrice = 100 * 10 ** 18;
    uint256 packSize = 2;

    // Variável para armazenar um pack fixo
    CardType[] fixedPack;

    function setUp() public {
        // Deploy dos mocks
        usdc = new MockERC20();
        vm.prank(owner);
        album = new CollectibleAlbum("NFT Album", "NFTALB", "ipfs://album-uri", owner, 100);
        // Deploy do contrato CardPackSale
        sale = new CardPackSale(address(usdc), address(album), cardPackPrice, packSize, treasury);
        // Mintar USDC para o comprador
        usdc.mint(buyer, 1000 * 10 ** 18);

        vm.startPrank(owner);
        // Configurar 3 tipos de cards
        album.addCardType(1, 100, RarityType.COMMON, "Card A", "ipfs://cardA");
        album.addCardType(2, 100, RarityType.COMMON, "Card B", "ipfs://cardB");
        album.setCardTypeSupply(2, 85);
        album.addCardType(3, 100, RarityType.LEGENDARY, "Card C", "ipfs://cardC");
        album.addCardType(4, 100, RarityType.RARE, "Card D", "ipfs://cardD");
        album.setCardTypeSupply(4, 98);
        album.addCardType(5, 100, RarityType.COMMON, "Card E", "ipfs://cardE");
        album.setCardTypeSupply(5, 100);
        album.transferOperator(address(sale));
        vm.stopPrank();

        /* Converter o array para memória e configurar o pack fixo no album mock
        CardType[] memory packMemory = new CardType[](packSize);
        for (uint256 i = 0; i < packSize; i++) {
            packMemory[i] = fixedPack[i];
        }
        album.setFixedPack(packMemory);
        */
    }

    /// @dev Testa o fluxo de compra do card pack com sucesso.
    function testBuyCardPack_Success() public {
        // O comprador aprova o contrato de venda para gastar o valor do pack
        vm.prank(buyer);
        usdc.approve(address(sale), cardPackPrice);

        // Salva os balanços iniciais de USDC
        for (uint256 index = 0; index < 1000000; index++) {
            vm.warp(block.timestamp + block.prevrandao);
        }
        vm.warp(block.timestamp + block.prevrandao);
        uint256 buyerInitialBalance = usdc.balanceOf(buyer);
        uint256 treasuryInitialBalance = usdc.balanceOf(treasury);

        // Compra o pack
        vm.prank(buyer);
        CardType[] memory pack = sale.buyCardPack();

        // Verifica se o pack retornado possui o tamanho correto
        assertEq(pack.length, packSize, "Returned pack size mismatch");

        // Verifica a transferência de USDC: o comprador deve ter perdido o valor do pack e o tesouro recebido
        uint256 buyerFinalBalance = usdc.balanceOf(buyer);
        uint256 treasuryFinalBalance = usdc.balanceOf(treasury);
        assertEq(
            buyerFinalBalance, buyerInitialBalance - cardPackPrice, "Buyer balance should decrease by cardPackPrice"
        );
        assertEq(
            treasuryFinalBalance,
            treasuryInitialBalance + cardPackPrice,
            "Treasury balance should increase by cardPackPrice"
        );

        ERC1155 nft = CollectibleAlbum(address(album));
        for (uint256 index = 0; index < pack.length; index++) {
            console.log(pack[index].id);

            //console.log(album.getCardType(index].id);
            uint256 bl = nft.balanceOf(buyer, pack[index].id);
            assertEq(1, bl, "buy balance should increase by 1");
        }
        /* Verifica se a função mintCardType foi chamada para cada card do pack
        uint256 mintCalls = album.getMintCallsLength();
        assertEq(mintCalls, packSize, "mintCardType should be called for each card in pack");

        // Verifica cada chamada de mint
        for (uint256 i = 0; i < mintCalls; i++) {
            (uint256 mintedId, address mintedTo, uint256 mintedAmount) = album.mintCalls(i);
            assertEq(mintedTo, buyer, "Mint recipient should be buyer");
            assertEq(mintedAmount, 1, "Mint amount should be 1");
        }*/
    }

    /// @dev Testa que a compra do card pack falha se o comprador não aprovar o valor necessário.
    function testBuyCardPack_FailsWithoutApproval() public {
        vm.prank(buyer);
        vm.expectRevert("Insufficient allowance");
        sale.buyCardPack();
    }
}
