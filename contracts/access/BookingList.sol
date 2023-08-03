// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";

abstract contract BookingList is AdminControl {

    mapping(bytes => string) public _bookingList;
	
	bool public _isBookingListActive = false;

    function setBookingListActive() public onlyOwner {
        _isBookingListActive = !_isBookingListActive;
    }

    function addBookingLists(string[] calldata names) public onlyMinterController {
        for (uint256 i = 0; i < names.length; i++) 
		{
            _bookingList[bytes(names[i])] = names[i];
        }
    }
	
	function addBookingList(string calldata name) public onlyMinterController {
        _bookingList[bytes(name)] = name;
    }
	
	function removeBookingList(string calldata name) public onlyMinterController {
		delete _bookingList[bytes(name)];
    }
	
	function chkInBookingList(string calldata name) public view returns (bool) {
		string memory _name = _bookingList[bytes(name)];
        return bytes(_name).length > 0;
    }
}