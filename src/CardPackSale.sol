// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
contract CardPackSale {
    IERC20 public usdcToken;
    ICollectiblesType public album;
    uint256 public cardPackPrice;
    uint256 public packSize;
    address public treasury;

    event CardPackPurchased(address indexed buyer, CardType[] pack);

    /**
     * @dev Construtor do contrato.
     * @param _usdcToken Endereço do token USDC.
     * @param _album Endereço do contrato CollectibleAlbum.
     * @param _cardPackPrice Preço do card pack (em USDC, considerando os decimais do token).
     * @param _packSize Quantidade de cards por pack.
     * @param _treasury Endereço que receberá os pagamentos.
     */
    constructor(address _usdcToken, address _album, uint256 _cardPackPrice, uint256 _packSize, address _treasury) {
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
    function buyCardPack() external returns (CardType[] memory pack) {
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
}
