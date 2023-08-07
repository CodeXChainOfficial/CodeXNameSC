// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/WhiteList.sol";
import "./access/BookingList.sol";
import "./utils/StringUtil.sol";

contract FIFSRegistrar is WhiteList, BookingList
{
    bool public _saleIsActive = true;
	
	bool public _saleTwoCharIsActive = false;

	uint256 private _price = 1;
	
	uint256 private _2chartimes = 100;
	
	uint256 private _3chartimes = 20;
	
	uint256 private _4chartimes = 5;

	function getPrice() public view returns (uint256) {
        return _price;
    }
	
	function setTimes(uint256 _2chartimenew, uint256 _3chartimenew, uint256 _4chartimenew) public onlyOwner {
		_2chartimes = _2chartimenew;
        _3chartimes = _3chartimenew;
		_4chartimes = _4chartimenew;
    }
	
	function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }
	
	function setSaleStateTwoChar() public onlyOwner {
        _saleTwoCharIsActive = !_saleTwoCharIsActive;
    }
    
	function setSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function buyDomain(string memory domain, string memory tld) external payable 
	{
		require(_saleIsActive, "Sale must be active to buy");
		
		require(bytes(tld).length != 0, "Top level domain must be non-empty");
		
		require(isTLD(tld) == true, "Top level domain not exist");
		
		require(StringUtil.dotCount(domain) == 0, "Domains cannot contain dot");
		
		uint256 _length = bytes(domain).length;
		
		require(_length != 0, "Domain must be non-empty");	
		
		require(_length >= 2, "Domain requires at least 2 characters");	
		
		// Check BookingList
		if (_isBookingListActive == true){
			string memory domain_name = _bookingList[bytes(domain)];
			require(bytes(domain_name).length == 0, "This name is already reserved");
		}
		
		
	    // Check WhiteList
		if (_isWhiteListActive == true){
			uint256 numbers = _whiteList[msg.sender];
			require(numbers > 0, "The address is not in the Whitelist");
			require(numbers >= balanceOf(msg.sender), "Exceeded max available to purchase");
		}
		
		if (_length == 2)
		{
			require(_saleTwoCharIsActive == true, "2 Character domain names need to be allowed to buy");
			
			require(msg.value >= _price.mul(_2chartimes), "Insufficient Token or Token value sent is not correct");
		}
	
		if (_length == 3)
		{
			require(msg.value >= _price.mul(_3chartimes), "Insufficient Token or Token value sent is not correct");
		}
		
		if (_length == 4)
		{
			require(msg.value >= _price.mul(_4chartimes), "Insufficient Token or Token value sent is not correct");
		}
		
		if (_length >= 5)
		{
			require(msg.value >= _price, "Insufficient Token or Token value sent is not correct");
		}
		
		string memory _domain = StringUtil.toLower(domain);
		
		string memory _tld = StringUtil.toLower(tld);
		
		_domain = string(abi.encodePacked(_domain, ".", _tld));
		
		uint256 tokenId = genTokenId(_domain);
		
		require (!_exists(tokenId), "Domain already exists");
		
	   _safeMint(msg.sender, tokenId);
	   
	   _setTokenURI(tokenId, _domain);
	   
	   emit NewURI(tokenId, _domain);
    }
}