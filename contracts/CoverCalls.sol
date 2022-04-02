// SPDX-License-Identifier: MIT
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
        bulkTransfer(nftcontract, nftid);
        
        //uint balance = address(this).balance;
        //bool success = payable(msg.sender).send(address(this).balance);
        //require(success, "Payment did not go through!");
        return true;

    }
    function owner_close() external payable returns (bool){

    }
    receive() external payable {
         ERC721 token = ERC721(nftcontract);
         token.setApprovalForAll(address(this), true);    
    }    
    fallback() external payable {
         ERC721 token = ERC721(nftcontract);
         token.setApprovalForAll(address(this), true);
    }

 }

abstract contract CoveredCalls is IERC2981, ERC721Enumerable, Ownable{
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


    function seller_create_call(uint _strikeprice, uint _expires, uint _price, bytes32 _salt, address _nftcontract, uint _nftid) external payable noReentry returns (address){
             require(sellingEnabled=true, "Selling Disabled");
             require(msg.value > sellfee);
             call_option _contract = new call_option{
                 salt:bytes32(_salt)
             }(msg.sender, _strikeprice, _expires, _price, _nftcontract, _nftid);
             address contract_address = address(_contract);
             _callContractCounter.increment();
             mint(1);
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
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
 }
 
