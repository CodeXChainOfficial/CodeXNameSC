// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AdminControl.sol";

abstract contract WhiteList is AdminControl {

    mapping(address => uint256) public _whiteList;
	
	bool public _isWhiteListActive = false;

    function setWhiteListActive() public onlyOwner {
        _isWhiteListActive = !_isWhiteListActive;
    }

    function addWhiteLists(address[] calldata accounts, uint256 numbers) public onlyMinterController {
        for (uint256 i = 0; i < accounts.length; i++) 
		{
            _whiteList[accounts[i]] = numbers;
        }
    }
	
	function addWhiteList(address account, uint256 numbers) public onlyMinterController {
        _whiteList[account] = numbers;
    }
	
	function numberInWhiteList(address addr) public view returns (uint256) {
        return _whiteList[addr];
    }
	
	function chkInWhiteList(address addr) public view returns (bool) {
        return _whiteList[addr] > 0;
    }
}