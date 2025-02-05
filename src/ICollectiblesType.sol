// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./DataType.sol";

interface ICollectiblesType {
    event MintCardType(uint256 indexed idType, address indexed to, uint256 amount);

    event URICardType(uint256 indexed idType, string uri);

    event SupplyCardType(uint256 indexed idType, uint256 newSupply);

    function transferOwner(address newOwner) external;

    function ownerProducer() external view returns (address);

    function getOperator() external view returns (address);

    function transferOperator(address newOperator) external;

    function getCollectiblesURI() external view returns (string memory);

    function addCardType(
        uint256 id,
        uint256 maxSupply,
        RarityType rarityType,
        string calldata nameType,
        string calldata uri
    ) external;

    function getCardType(uint256 id) external view returns (CardType memory);

    function setCardURI(uint256 id, string memory newUri) external;

    function uri(uint256 id) external view returns (string memory);

    function setCardTypeSupply(uint256 id, uint256 newSupply) external;

    function mintCardType(uint256 id, address to, uint256 amount) external;

    function getRandomAvailableCardTypes(uint256 count) external view returns (CardType[] memory);
}
