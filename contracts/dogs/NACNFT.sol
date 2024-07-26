// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20 {
     function transferFrom(address from, address to, uint256 value) external returns (bool);
     function decimals() external view returns (uint8);
}

contract NACNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
 
    uint256 public curTokenId;

    uint private _max = 600;
    uint public price = 200;
   
    string public baseURIextended = "https://ipfs.supremelegend.io/ipfs/QmaMrFswfDvTLic3MPZfYWPamUh2C96JJJtLrs3ouhz5Qh";

    address public usdt = 0x55d398326f99059fF775485246999027B3197955;

    address public vault = 0x26eD8c80d9b1F8481e7F36271FD24b8a07499Db4;

    bool public isPause;
    
    mapping(address => bool) public minted;

    constructor() ERC721("NAC", "NAC NFT"){
        for(uint i; i<100; i++){
            _mint();
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIextended;
    }

    function setUSDT(address _usdt) external onlyOwner {
        usdt = _usdt;
    }

    function setPause(bool _status) external onlyOwner {
        isPause = _status;
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURIextended = __baseURI;
    }

    function setVault(address _addr)external onlyOwner{
        vault = _addr;
    }

    function setPrice(uint _price)external onlyOwner{
        price = _price;
    }

    function _mint() private {
        curTokenId++;
        _safeMint(msg.sender, curTokenId);
        _setTokenURI(curTokenId, "");
    }

    function safeMint(address _to) public {
        require(!minted[msg.sender] ,"Caller already minted.");
        minted[msg.sender] = true;
        curTokenId++;
        require(curTokenId <= _max,"more than 600.");
        require(!isPause,"Mint action is pause.");

        uint _decimals = IERC20(usdt).decimals();
        IERC20(usdt).transferFrom(msg.sender, vault, price * 10 ** _decimals);

        _safeMint(_to, curTokenId);
        _setTokenURI(curTokenId, "");

        // Check if we need to pause the contract 200 360
        if (curTokenId == 300 || curTokenId == 460) isPause = true;

        if(curTokenId == 300 ) price = 250;
        if(curTokenId == 460 ) price = 300;
        
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getUserNFTs(address _user) public view returns (uint[] memory) {
        uint length = balanceOf(_user);
        uint[] memory ids = new uint[](length);
        for (uint i; i < ids.length; i++) {
            ids[i] = tokenOfOwnerByIndex(_user, i);
        }
        return ids;
    }
}
