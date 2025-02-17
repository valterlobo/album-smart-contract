// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./DataType.sol";
import "./ICollectiblesType.sol";

/**
 * @dev Interface para interação com o contrato CollectibleAlbum.
 * É necessário que o contrato CollectibleAlbum possua os métodos:
 * - getRandomAvailableCardTypes(uint256 count) external view returns (CardType[] memory)
 * - mintCardType(uint256 id, address to, uint256 amount) external
 *
 * Também se utiliza o struct CardType e o enum RarityType, conforme definido no seu projeto.
 */

/// @title CardPackSale
/// @notice Contrato para venda de pacotes de cards usando USDC
contract CardPackSale is Ownable, ReentrancyGuard {
    IERC20 public usdcToken;
    ICollectiblesType public immutable album;
    uint256 public cardPackPrice;
    uint256 public packSize;
    address public treasury;

    event CardPackPurchased(address indexed buyer, CardType[] pack);
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
     * @dev Permite a compra de um card pack.
     * O comprador precisa ter aprovado o valor do card pack para este contrato.
     * Após o pagamento, o contrato obtém aleatoriamente um pacote de cards disponíveis,
     * e para cada card do pacote executa a mintagem de 1 unidade para o comprador.
     * @return pack O array com os CardTypes sorteados.
     */
    function buyCardPack() external nonReentrant returns (CardType[] memory pack) {
        // Transfere o valor do card pack do comprador para o tesouro
        require(usdcToken.transferFrom(msg.sender, treasury, cardPackPrice), "USDC payment failed");

        // Obtém aleatoriamente 'packSize' CardTypes disponíveis
        pack = album.getRandomAvailableCardTypes(packSize);
        require(pack.length == packSize, "Failed to obtain card pack");

        // Para cada CardType sorteado, mint 1 unidade para o comprador.
        for (uint256 i = 0; i < pack.length; i++) {
            album.mintCardType(pack[i].id, msg.sender, 1);
        }

        emit CardPackPurchased(msg.sender, pack);
    }

    // Getter methods (optional, since public vars already generate them)
    function getUsdcToken() external view returns (IERC20) {
        return usdcToken;
    }

    function getCardPackPrice() external view returns (uint256) {
        return cardPackPrice;
    }

    function getPackSize() external view returns (uint256) {
        return packSize;
    }

    function getTreasury() external view returns (address) {
        return treasury;
    }

    // Setter methods (with access control)
    function setUsdcToken(IERC20 ctrUsdcToken) external onlyOwner {
        require(ctrUsdcToken != IERC20(address(0)), "Invalid address");
        usdcToken = ctrUsdcToken;
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

    function setTreasury(address addrTreasury) external onlyOwner {
        require(addrTreasury != address(0), "Invalid address");
        emit TreasuryUpdated(treasury, addrTreasury);
        treasury = addrTreasury;
    }
}
