// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/*
Covered Call Contracts For OG Social Club https://discord.gg/tailopeznft 
By: Chillininvt_OGC John Anderson Vermont Internet Design LLC, Vermont DEFI

On Request for prototype code by Dr. Alex Mehr on Ama Session on March 30, 2022

 */
// Developed By https://www.vermontdefi.com  

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
// File: contracts/TestNFT.sol
contract TestNFT is IERC2981, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter _tokenIdTracker;
    string public baseURI = 'http://vermontdefi.com/nft/json/';
    uint16 public reserve = 500;
    uint public mintPrice = 20000000000000000;
    uint256 public additionalFees = 0;
    bool public mintingEnabled = false;
    bool internal locked;
    modifier noReentry() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
    
    mapping(address => uint32) public addressMintedBalance;
    
    event event_withdrawal(address indexed user, uint etherAmount, uint depositTime);
    event event_placeorder(address indexed user, uint etherAmount, uint orderTime);
    event event_setmintprice(uint mintprice);
    event event_setfee(uint additionalfee); 
    
    constructor() ERC721("TestNFT", "TNFT") { }
    receive() external payable {}    
    fallback() external payable {}

    function supportsInterface(bytes4 _interfaceId) public view virtual override(IERC165, ERC721Enumerable) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "ERC2981RoyaltyStandard: Royalty info for nonexistent token");
        return (owner(), _salePrice / 10); // 10 percent
    }   

    // public
    function setMintPrice(uint  _mintPrice) public onlyOwner{
          mintPrice = _mintPrice;
          emit event_setmintprice( _mintPrice); 
           
    }
    function getMintPrice() public view returns (uint){
         return mintPrice;
    }
    function setFeePrice(uint _additionalFee) public onlyOwner{
          additionalFees = _additionalFee;
          emit event_setfee( _additionalFee);            
    }
    function getFeePrice() public view returns (uint){
         return additionalFees;
    }
    function mint(uint32 _mintAmount) private{ 
        require(totalSupply() + _mintAmount < 16_500, "Request will exceed max supply!");
         addressMintedBalance[msg.sender] += 1;
         _safeMint(msg.sender, _tokenIdTracker.current());
         _tokenIdTracker.increment();
    }

    function _mintLoop(address to, uint32 amount) private {
        addressMintedBalance[to] += amount;
        for (uint i; i < amount; i++ ) {
            _safeMint(to, _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }
    function getTokenId() external view returns(uint){
        return _tokenIdTracker.current();
    }
    function placeOrder(uint32 _mintAmount, uint _miscFees) public payable noReentry returns (bool){
           require(mintingEnabled == true);  
           require(_mintAmount > 0 , 'You Must Mint at least one nft');
           uint orderTotal =  uint(mintPrice) * uint(_mintAmount) + uint(_miscFees) + uint(additionalFees);
           require(msg.value >= orderTotal, "Ethereum amount sent is not enough!");
           mint(1);
           emit event_placeorder(msg.sender, msg.value, block.timestamp);
           return true;
        
    }
   

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    //only owner
    function ownerMintFromReserve(address mintto, uint16 amount) public onlyOwner {
        require(reserve >= amount, "Not enough tokens left in reserve!");
        _mintLoop(mintto, amount);
        reserve -= amount;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    } 

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

   function withdraw() external onlyOwner noReentry{   
        uint balance = address(this).balance;
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Payment did not go through!");
        emit event_withdrawal(msg.sender, block.timestamp, balance);
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}