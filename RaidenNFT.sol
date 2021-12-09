//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";
import "./IRaidenNFT.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract RaidenNFT is IRaidenNFT, ERC1155, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public openseaWhitelistProxyAddress;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    mapping(uint256 => uint256) public nftsCount;
    mapping(uint256 => uint256) public nftsType;


    constructor(address _proxyRegistryAddress) ERC1155("https://api.raiden.app/metadata/nft/{id}.json") {
        openseaWhitelistProxyAddress = _proxyRegistryAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155, AccessControl) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function getNftTypeCount(uint256 typeId) public view returns (uint256) {
        return nftsCount[typeId];
    }

    function getNftType(uint256 id) public view returns (uint256) {
        return nftsType[id];
    }

    function contractURI() public pure returns (string memory) {
        // https://docs.opensea.io/docs/contract-level-metadata

        return "https://api.raiden.app/metadata/nft.json";
    }

    function _getNextTokenID() private view returns (uint256) {
        return _tokenIds.current() + 1;
    }

    function _incrementTokenTypeId() private  {
        _tokenIds.increment();
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override(IERC1155, ERC1155) returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaWhitelistProxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public 
        onlyRole(BURNER_ROLE)
     override {
        nftsCount[nftsType[id]]--;
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids
    ) public 
        onlyRole(BURNER_ROLE)
     override {
        uint256[] memory amounts = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            nftsCount[nftsType[ids[i]]]--;

            amounts[i] = 1;
        }

        _burnBatch(account, ids, amounts);
    }

    function mint(
        address account,
        uint256 nftType
    )
        public
        onlyRole(MINTER_ROLE)
        override
        returns (uint256)
    {
        uint256 newItemId = _getNextTokenID();
        _incrementTokenTypeId();

        nftsType[newItemId] = nftType;
        nftsCount[nftType]++;
        
        _mint(account, newItemId, 1, "");

        return newItemId;
    }

    function mintBatch(
        address account,
        uint256[] memory nftTypes
    )
        public
        onlyRole(MINTER_ROLE)
        override
        returns (uint256[] memory)
    {
        uint256[] memory itemIds = new uint256[](nftTypes.length);
        uint256[] memory amounts = new uint256[](nftTypes.length);

        for (uint256 i = 0; i < nftTypes.length; i++) {
            uint256 newItemId = _getNextTokenID();
            _incrementTokenTypeId();

            nftsType[newItemId] = nftTypes[i];
            nftsCount[nftTypes[i]]++;

            itemIds[i] = newItemId;
            amounts[i] = 1;
        }

        _mintBatch(account, itemIds, amounts, "");

        return itemIds;
    }

    function setURI(string memory newuri) public onlyRole(CONFIG_ROLE) {
        _setURI(newuri);
    }
}