// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./DataType.sol";
import "./ICollectiblesType.sol";

/**
 * @dev Interface para interação com o contrato CollectibleAlbum.
 * É necessário que o contrato CollectibleAlbum possua os métodos:
 * - getRandomAvailableCardTypes(uint256 count) external  returns (CardType[] memory)
 * - mintCardType(uint256 id, address to, uint256 amount) external
 *
 * Também se utiliza o struct CardType e o enum RarityType, conforme definido no seu projeto.
 */

/// @title CardPackSale
/// @notice Contrato para venda de pacotes de cards usando USDC
contract CardPackSale is Ownable, ReentrancyGuard {
    IERC20 public immutable usdcToken;
    ICollectiblesType public immutable album;
    uint256 public cardPackPrice;
    uint256 public packSize;
    address public treasury;

    using SafeERC20 for IERC20;

    event CardPackPurchased(address indexed buyer, uint256 packSize, uint256 price, uint256 timestamp);
    event CardPackPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event PackSizeUpdated(uint256 oldSize, uint256 newSize);
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    /**
     * @dev Construtor do contrato.
     * @param _usdcToken Endereço do token USDC.
     * @param _album Endereço do contrato CollectibleAlbum.
     * @param _cardPackPrice Preço do card pack (em USDC, considerando os decimais do token).
     * @param _packSize Quantidade de cards por pack.
     * @param _treasury Endereço que receberá os pagamentos.
     */
    constructor(
        address _usdcToken,
        address _album,
        uint256 _cardPackPrice,
        uint256 _packSize,
        address _treasury,
        address _owner
    ) Ownable(_owner) {
        require(_usdcToken != address(0), "Invalid USDC token address");
        require(_album != address(0), "Invalid album address");
        require(_treasury != address(0), "Invalid treasury address");

        usdcToken = IERC20(_usdcToken);
        album = ICollectiblesType(_album);
        cardPackPrice = _cardPackPrice;
        packSize = _packSize;
        treasury = _treasury;
    }

    /**
     * OBS :  ( Falta de limitação no tamanho dos pacotes)
     *       Mudar o metodo para compra de figuras
     *       de modo aleatorio que ainda tenha figuras pra venda -
     *       ex qtd figurinhas > disponivel para venda ?????
     * @dev Permite a compra de um card pack.
     * O comprador precisa ter aprovado o valor do card pack para este contrato.
     * Após o pagamento, o contrato obtém aleatoriamente um pacote de cards disponíveis,
     * e para cada card do pacote executa a mintagem de 1 unidade para o comprador.
     * @return pack O array com os CardTypes sorteados.
     */
    function buyCardPack() external nonReentrant returns (CardType[] memory pack) {
        require(usdcToken.balanceOf(msg.sender) >= cardPackPrice, "Insufficient USDC balance");
        require(usdcToken.allowance(msg.sender, address(this)) >= cardPackPrice, "Insufficient allowance");

        // Obtém aleatoriamente 'packSize' CardTypes disponíveis
        pack = album.getRandomAvailableCardTypes(packSize);
        require(pack.length == packSize, "Failed to obtain card pack");

        // Transfere o valor do card pack do comprador para o tesouro
        usdcToken.safeTransferFrom(msg.sender, treasury, cardPackPrice);

        // Para cada CardType sorteado, mint 1 unidade para o comprador.
        for (uint256 i = 0; i < pack.length; i++) {
            album.mintCardType(pack[i].id, msg.sender, 1);
        }
        emit CardPackPurchased(msg.sender, packSize, cardPackPrice, block.timestamp);
    }

    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid address");
        emit TreasuryUpdated(treasury, newTreasury);
        treasury = newTreasury;
    }

    function setCardPackPrice(uint256 intCardPackPrice) external onlyOwner {
        require(intCardPackPrice > 0, "Price must be greater than 0");
        emit CardPackPriceUpdated(cardPackPrice, intCardPackPrice);
        cardPackPrice = intCardPackPrice;
    }

    function setPackSize(uint256 intPackSize) external onlyOwner {
        require(intPackSize > 0, "Pack size must be greater than 0");
        emit PackSizeUpdated(packSize, intPackSize);
        packSize = intPackSize;
    }
}
