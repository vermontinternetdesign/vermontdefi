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
import "./call_option.sol";



contract CoveredCalls is IERC2981, ERC721Enumerable, Ownable{
    using Strings for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    Counters.Counter _callContractCounter;
    Counters.Counter _nftTokenCounter;
    bool public buyingEnabled = false;     
    bool public sellingEnabled = false;
    uint public buyfee = 10000000000000000; //0.01
    uint public sellfee = 10000000000000000; //0.01
    string public baseURI;
    uint16 public reserve = 500;
    uint public mintPrice = 20000000000000000;
    uint256 public additionalFees = 0;
    bool public mintingEnabled = false;
    bool internal locked;
    mapping(address => uint32) public addressMintedBalance;
    modifier noReentry() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }    
    event event_withdrawal(address indexed user, uint etherAmount, uint depositTime);
    event event_callcreated(address indexed user, uint strikeprice, uint expires, uint price, address contract_address,  uint orderTime);
    event event_setmintprice(uint mintprice);
    event event_setfee(uint additionalfee); 

    receive() external payable {}    
    fallback() external payable {}
    constructor() ERC721("VTID Covered Call", "VTIDCC") { }
    function appoveTransfer(address _nftcontract) external {
        ERC721 token = ERC721(_nftcontract);
         token.setApprovalForAll(address(this), true);
    }
    function seller_create_call(uint _strikeprice, uint _expires, uint _price, bytes32 _salt, address _nftcontract, uint _nftid) external payable noReentry returns (address){
             require(sellingEnabled=true, "Selling Disabled");
             require(msg.value > sellfee);
             ERC721 token = ERC721(_nftcontract);
             require(token.balanceOf(msg.sender) > 0, "You dont own this toke");
             require(token.ownerOf(_nftid) == msg.sender, "This contract doesn't own NFT");            
             call_option _contract = new call_option{
                 salt:bytes32(_salt)
             }(msg.sender, _strikeprice, _expires, _price, _nftcontract, _nftid);
             address contract_address = address(_contract);
             _callContractCounter.increment();
             mint(1);
             token.transferFrom(msg.sender, contract_address, _nftid);            
             emit event_callcreated(msg.sender, _strikeprice, _expires, _price, contract_address, block.timestamp);
             return (contract_address);
    }
    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (owner(), _salePrice / 10); // 10 percent
    } 
    function mint(uint32 _mintAmount) private{ 
         require(totalSupply() + _mintAmount < 16_500, "Request will exceed max supply!");
         addressMintedBalance[msg.sender] += 1;
         _safeMint(msg.sender, _nftTokenCounter.current());
         _nftTokenCounter.increment();
    }
    function getTokenId() external view returns(uint){
        return _nftTokenCounter.current();
    }
    function withdraw() external onlyOwner noReentry{   
        uint balance = address(this).balance;
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Payment did not go through!");
        emit event_withdrawal(msg.sender, block.timestamp, balance);
    }
     function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
     function _mintLoop(address to, uint32 amount) private {
        addressMintedBalance[to] += amount;
        for (uint i; i < amount; i++ ) {
            _safeMint(to,  _nftTokenCounter.current());
             _nftTokenCounter.increment();
        }
    }
    //only owner
    function ownerMintFromReserve(address mintto, uint16 amount) public onlyOwner {
        require(reserve >= amount, "Not enough tokens left in reserve!");
        _mintLoop(mintto, amount);
        reserve -= amount;
    }    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
 }
 
