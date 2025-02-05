// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

enum RarityType {
    COMMON,
    RARE,
    EPIC,
    LEGENDARY
}

struct AddressData {
    address value;
    bool exists;
}

struct CardType {
    string name;
    string uri;
    uint256 id;
    uint256 maxSupply;
    uint256 supply;
    RarityType rarityType;
}

struct CardPack {
    uint256[] card_type_ids;
    uint256 price;
    uint256 quantity;
}

/*
cod char(40) [primary key]
title varchar(400)
info  jsonb 
url_info varchar(400)  
token_id bigint
rarity_type RarityType
collectible_album_id UUID 

Table CardPack {
  id UUID [primary key]
  quantity bigint  
  price bigint 
  collectible_album_id UUID
  card_type_cod char(40)
  card_types jsonb  //store cardType 
}

*/
