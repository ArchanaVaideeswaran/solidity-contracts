// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract WhalezAuction is ERC721Enumerable {
  using Strings for uint256;

  struct Bidder {
    uint256 id;
    uint256 tokenId;
    uint256 bidAmount;
    address user;
  }

  string public baseURI = "https://whaleznftauction.com/metadata/";
  string public baseExtension = ".json";

  uint256 public cost = 0.05 ether;
  uint256 public threshold = 0.1 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 2;
  uint256 public totalMinted;
  uint256 counter;

  address owner;

  mapping(uint256 => Bidder) BidderMap;

  constructor() ERC721("Diatom Whalez", "DWZ") {
    counter = 0;
    owner = msg.sender;
    mint(msg.sender);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to) public payable {
    uint256 minted = totalMinted;
    
    if (msg.sender != owner) {
      require(msg.value >= cost);
      counter = counter + 1;
      uint256 bidAmount = msg.value;
      BidderMap[counter] = Bidder(counter, minted + 1, bidAmount, _to);
      if(bidAmount >= threshold){
        _safeMint(_to, minted + 1);
        totalMinted = totalMinted + 1;
      }
    }
    else{
      _safeMint(_to, minted + 1);
      totalMinted = totalMinted + 1;
    }
  }

  function getBidders(uint256 _tokenId) public view returns (Bidder[] memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    Bidder[] memory biddersForTokenID;
    uint256 index = 0;
    for(uint256 i = 1; i <= counter; i++){
      if(BidderMap[i].tokenId == _tokenId){
        biddersForTokenID[index] = BidderMap[i];
        index = index + 1;
      }
    }
    return biddersForTokenID;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  // function mintOnlyOwner(address _to, uint256 _mintAmount) public payable{
  //   uint256 minted = totalSupply();
  //   require(_mintAmount > 0);
  //   require(_mintAmount <= maxMintAmount);
  //   require(minted + _mintAmount <= maxSupply);
  //   for (uint256 i = 1; i <= _mintAmount; i++) {
  //     _safeMint(_to, minted + i);
  //   }
  // }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
    threshold = cost * 2;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function withdraw() public payable onlyOwner {
    // This will payout the owner 95% of the contract balance.
    (bool os, ) = payable(owner).call{value: address(this).balance}("");
    require(os);
  }
}