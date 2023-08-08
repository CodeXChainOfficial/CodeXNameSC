// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access/WhiteList.sol";
import "./access/BookingList.sol";
import "./utils/StringUtil.sol";
import "./PriceOracle.sol";
import "./interfaces/IDomainRegistrar.sol";

contract FIFSRegistrar is WhiteList, BookingList
{
    bool public _saleIsActive = false;
	
	uint256 public _3chartimes = 150;
	
	uint256 public _4chartimes = 100;
	
	uint256 public _5chartimes = 20;

	uint256 public _6chartimes = 10;

	uint256 public _7chartimes = 6;

    PriceOracle public _price;
	IDomainRegistrar public _codex;

    constructor(PriceOracle price, IDomainRegistrar codex) {
		_price = price;
		_codex = codex;
	}

	function getPrice() public view returns (uint256) {
        return _price.current_price;
    }
	
	function setTimes(uint256[5] memory newTimes) public onlyOwner {
        _3chartimes = newTimes[0];
		_4chartimes = newTimes[1];
		_5chartimes = newTimes[2];
		_6chartimes = newTimes[3];
		_7chartimes = newTimes[4];
    }
	
	function setPrice(PriceOracle price) public onlyOwner {
        _price = price;
    }

	function setDomainRegistrar(IDomainRegistrar codex) public onlyOwner {
        _codex = codex;
    }
    
	function setSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function buyDomain(string memory domain, string memory tld) external payable 
	{
		require(_saleIsActive, "Sale must be active to buy");
		
		uint256 _length = bytes(domain).length;
		
		require(_length != 0, "Domain must be non-empty");	
		
		require(_length >= 3, "Domain requires at least 2 characters");	
		
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

		uint256 trxPerUSD = getPrice();
		uint256 timesPerLen = _7chartimes;
		
		if (_length == 3)
		{
			timesPerLen = _3chartimes;
		}
		
		if (_length == 4)
		{
			timesPerLen = _4chartimes;
		}

		if (_length == 5)
		{
			timesPerLen = _5chartimes;
		}

		if (_length == 6)
		{
			timesPerLen = _6chartimes;
		}
		
		require(msg.value >= trxPerUSD.mul(timesPerLen), "Insufficient Token or Token value sent is not correct");
		
		_codex.registerDomain(_msgSender(), domain, tld);
    }
}