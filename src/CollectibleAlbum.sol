// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/*
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./DataType.sol";
import "./ICollectiblesType.sol";

contract CollectibleAlbum is ICollectiblesType, Ownable, ERC1155 {
    string public name;
    string public symbol;
    string public uriCollectibleAlbum;
    address public operator;
    uint256 public immutable quantity;
    uint256 public randNonce = 0;

    mapping(uint256 => CardType) public cardTypes;
    //Array para armazenar os IDs dos CardTypes adicionados (para iteração)
    uint256[] public cardTypeIds;

    constructor(
        string memory nameCollectibles,
        string memory symbolCollectibles,
        string memory uriCollectibles,
        address addrOwnerlCollectibles,
        uint256 qtd
    ) Ownable(addrOwnerlCollectibles) ERC1155("") {
        require(addrOwnerlCollectibles != address(0), "operator can't the zero address");
        require(qtd > 0, "Album quantity can't the zero");
        name = nameCollectibles;
        symbol = symbolCollectibles;
        uriCollectibleAlbum = uriCollectibles;
        operator = addrOwnerlCollectibles;
        quantity = qtd;
    }

    // ~~~~~~~~~~~~~~~~~~~~ Modifiers ~~~~~~~~~~~~~~~~~~~~
    modifier activeCardType(uint256 id) {
        require(_exists(id), "This CardType does not exist yet, check back later!");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Operator UNAUTHORIZED");
        _;
    }

    function transferOwner(address newOwner) external virtual onlyOwner {
        super.transferOwnership(newOwner);
    }

    function ownerProducer() public view virtual returns (address) {
        return owner();
    }

    function getCollectiblesURI() external view returns (string memory) {
        return uriCollectibleAlbum;
    }

    function addCardType(
        uint256 id,
        uint256 maxSupply,
        RarityType rarityType,
        string calldata nameType,
        string calldata uriCard
    ) external onlyOwner {
        require(!_exists(id), "This CardType EXIST [ID]");
        require(maxSupply == quantity, "maxSupply can be equal to initial quantity");

        CardType memory newCardType = CardType(nameType, uriCard, id, maxSupply, 0, rarityType);

        cardTypes[id] = newCardType;
        cardTypeIds.push(id);
    }

    function getCardType(uint256 id) external view returns (CardType memory) {
        require(_exists(id), "This CardType EXIST [ID]");

        return cardTypes[id];
    }

    function setCardURI(uint256 id, string memory newUri) external onlyOwner activeCardType(id) {
        cardTypes[id].uri = newUri;
        emit URICardType(id, newUri);
    }

    function getCardURI(uint256 id) public view virtual returns (string memory) {
        return cardTypes[id].uri;
    }

    function uri(uint256 id) public view virtual override(ERC1155) returns (string memory) {
        return getCardURI(id);
    }

    function setCardTypeSupply(uint256 id, uint256 newSupply) external onlyOwner activeCardType(id) {
        require(newSupply <= cardTypes[id].maxSupply, "newSupply exceeds the maximum supply limit");

        cardTypes[id].supply = newSupply;
        emit SupplyCardType(id, newSupply);
    }

    function mintCardType(uint256 id, address to, uint256 amount) external onlyOperator activeCardType(id) {
        require(
            cardTypes[id].supply + amount <= cardTypes[id].maxSupply, "Minting amount exceeds the maximum supply limit"
        );
        cardTypes[id].supply = cardTypes[id].supply + amount;
        _mint(to, id, amount, "");
        emit MintCardType(id, to, amount);
    }

    function getOperator() external view override returns (address) {
        return operator;
    }

    function transferOperator(address newOperator) external override onlyOwner {
        require(newOperator != address(0), "operator can't the zero address");
        emit TransferOperator(operator, newOperator);
        operator = newOperator;
    }

    /*
    function randMod() internal returns (uint256) {
        // increase nonce
        randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)));
    }*/

    /**
     * @dev Retorna aleatoriamente `count` CardTypes que ainda possuam supply disponível,
     * escolhendo-os com probabilidade ponderada pela raridade.
     * Requer que haja pelo menos `count` tipos disponíveis.
     */
    function getRandomAvailableCardTypes(uint256 count) external returns (CardType[] memory) {
        uint256 availableCount = 0;
        uint256 cardLength = cardTypeIds.length;
        // increase nonce
        randNonce++;

        // Conta quantos CardTypes possuem supply disponível
        for (uint256 i = 0; i < cardLength; i++) {
            uint256 id = cardTypeIds[i];
            if (cardTypes[id].supply < cardTypes[id].maxSupply) {
                availableCount++;
            }
        }
        require(availableCount >= count, "Not enough available card types");

        // Cria array para o resultado
        CardType[] memory selected = new CardType[](count);
        // Cria array temporário com os IDs disponíveis
        uint256[] memory availIds = new uint256[](availableCount);
        uint256 index = 0;
        for (uint256 i = 0; i < cardLength; i++) {
            uint256 id = cardTypeIds[i];
            if (cardTypes[id].supply < cardTypes[id].maxSupply) {
                availIds[index] = id;
                index++;
            }
        }

        uint256 currentLength = availableCount;
        // Seleciona, de forma ponderada, `count` CardTypes distintos
        for (uint256 j = 0; j < count; j++) {
            uint256 totalWeight = 0;
            // Calcula o total de pesos dos CardTypes disponíveis
            for (uint256 k = 0; k < currentLength; k++) {
                uint256 cardId = availIds[k];
                totalWeight += getWeight(cardTypes[cardId].rarityType);
            }
            // Gera um número pseudoaleatório entre 0 e totalWeight-1
            uint256 randomNumber = getRandomNumber(randNonce) % (totalWeight + randNonce);

            uint256 runningWeight = 0;
            uint256 selectedIndex = 0;
            // Seleciona o CardType com base no peso acumulado
            for (uint256 k = 0; k < currentLength; k++) {
                uint256 cardId = availIds[k];
                runningWeight += getWeight(cardTypes[cardId].rarityType);
                if (randomNumber < runningWeight) {
                    selectedIndex = k;
                    break;
                }
            }

            uint256 chosenId = availIds[selectedIndex];
            selected[j] = cardTypes[chosenId];

            // Remove o elemento escolhido da lista (swap com o último e diminui o "currentLength")
            availIds[selectedIndex] = availIds[currentLength - 1];
            currentLength--;
        }

        return selected;
    }

    function getRandomNumber(uint256 seed) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, msg.sender, seed)));
    }

    /**
     * @dev Função interna que retorna um peso para cada raridade.
     * Quanto maior o peso, maior a chance de ser selecionado.
     * COMMON, RARE,EPIC,LEGENDARY
     */
    function getWeight(RarityType rarity) internal pure returns (uint256) {
        if (rarity == RarityType.COMMON) {
            return 1001;
        } else if (rarity == RarityType.RARE) {
            return 105;
        } else if (rarity == RarityType.EPIC) {
            return 13;
        } else if (rarity == RarityType.LEGENDARY) {
            return 2;
        }
        return 1;
    }

    function _exists(uint256 id) internal view virtual returns (bool) {
        return cardTypes[id].id != 0;
    }
}
