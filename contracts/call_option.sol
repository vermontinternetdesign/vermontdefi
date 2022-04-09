// SPDX-License-Identifier: MIT

// For Example only not intened to be run in production.
// Example Call Option Management 
// Locks NFT into Contract call_option
// Author: John Anderson created at Barre,VT 
// By Vermont Internet Design LLC http://www.vermontdefi.com https://www.vermontinternetdesign.com

pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract call_option{
    address public owner;
    address public ownerofcall;
    uint public strikeprice;
    uint public created;
    uint public expires;
    uint public startprice;
    bool public allapproved;
    address public nftcontract;
    uint public nftid; 
    
    constructor(address _owner, uint _strikeprice, uint _expires, uint _price, address _nftcontract, uint _nftid){
         strikeprice = _strikeprice;
         owner = _owner;
         created = block.timestamp; 
         expires = _expires;
         startprice = _price;
         nftcontract = _nftcontract;
         nftid = _nftid;         
    }
    function bulkTransfer(address _contractAddress, uint256 _tokenId) private {
        ERC721 token = ERC721(_contractAddress);
        require(token.balanceOf(address(this)) > 0, "No tokens from this contract");
        require(token.ownerOf(_tokenId) == address(this), "This contract doesn't own NFT");
        token.transferFrom(address(this), msg.sender, _tokenId);
    }    
    function exercise() external payable returns(bool){
        require(ownerofcall == msg.sender,"You dont own the call contract");
        require(msg.value > strikeprice, "You must pay strike price");
        bulkTransfer(nftcontract, nftid);
        return true;
    }
    function update_price(uint _price)external {
        require(owner == msg.sender);
        startprice = _price;
    }
    function owner_close() external returns (bool){
          require(owner == msg.sender,"You dont write the call contract");
          bulkTransfer(nftcontract, nftid);
          return true;
    }
    receive() external payable {
         ERC721 token = ERC721(nftcontract);
         token.setApprovalForAll(address(this), true);
         require(token.ownerOf(nftid) == address(this), "This contract doesn't own NFT");
         allapproved == true;
    }    
    fallback() external payable {
         ERC721 token = ERC721(nftcontract);
         token.setApprovalForAll(address(this), true);
         require(token.ownerOf(nftid) == address(this), "This contract doesn't own NFT");
         allapproved == true;
    }

 }