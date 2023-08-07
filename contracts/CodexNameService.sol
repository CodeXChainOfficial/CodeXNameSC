// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/TRC721Enumerable.sol";
import "./access/WhiteList.sol";
import "./access/Ownable.sol";
import "./storage/RecordStorage.sol";
import "./utils/SafeMath.sol";
import "./utils/StringUtil.sol";
import "./utils/EnumerableSet.sol";

contract CodexNameService is TRC721Enumerable, RecordStorage, Ownable
{
	using SafeMath for uint256;
	 
	using EnumerableSet for EnumerableSet.UintSet;  
	
	event NewURI(uint256 indexed tokenId, string tokenUri);
		
	mapping (uint256 => EnumerableSet.UintSet) private _subDomains;

	mapping (uint256 => string) public _tokenURIs;
	
	mapping (uint256 => address) internal _tokenResolvers;
	
	mapping(address => uint256) private _tokenReverses;

    // Top Level Domain
    mapping(uint256 => string) private _tlds;
	
	string private _nftBaseURI = "";
	
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId)
        );
        _;
    }
	
	constructor() TRC721("Codex Name Service", "CDX") {
		
	}
	
    function isApprovedOrOwner(address account, uint256 tokenId) external view returns(bool)  {
        return _isApprovedOrOwner(account, tokenId);
    }
	
	
	function getOwner(string memory domain) external view returns (address)  {
		string memory _domain = StringUtil.toLower(domain);
	    uint256 tokenId = uint256(keccak256(abi.encodePacked(_domain)));
        return ownerOf(tokenId);
    }
		
	function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
	
	function setTLD(string memory _tld) public onlyOwner {
        uint256 tokenId = genTokenId(_tld);
		_tlds[tokenId] = _tld;
    }
	
	function isTLD(string memory _tld) public view returns (bool) {
		bool isExist = false;
        uint256 tokenId = genTokenId(_tld);
		if (bytes(_tlds[tokenId]).length != 0){
            isExist = true;
        }
		return isExist;
	}
	
	function _baseURI() internal view override returns (string memory) {
        return _nftBaseURI;
    }
    
    function setBaseURI(string memory _uri) external onlyOwner {
        _nftBaseURI = _uri;
    }
	
	function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "TRC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
		string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI, tokenId));
    }

	function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "TRC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

	function registerDomain(address to, string memory domain, string memory tld) external onlyMinterController 
	{
		require(to != address(0), "To address is null");
		
		require(bytes(tld).length != 0, "Top level domain must be non-empty");
		
		require(isTLD(tld) == true, "Top level domain not exist");
		
		require(bytes(domain).length != 0, "Domain must be non-empty");	
		
		require(StringUtil.dotCount(domain) == 0, "Domain not support");

		string memory _domain = StringUtil.toLower(domain);

		string memory _tld = StringUtil.toLower(tld);
		
		_domain = string(abi.encodePacked(_domain, ".", _tld));

		uint256 tokenId = genTokenId(_domain);
		
		require (!_exists(tokenId), "Domain already exists");
		
       _safeMint(to, tokenId);
	   
	   _setTokenURI(tokenId, _domain);
	   
	   emit NewURI(tokenId, _domain);
    }

	function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ITRC721, TRC721) {

        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");
		
		_reset(tokenId);
		
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ITRC721, TRC721) {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ITRC721, TRC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721: transfer caller is not owner nor approved");
		
		_reset(tokenId);
		
        _safeTransfer(from, to, tokenId, _data);
    }
		
	function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "TRC721Burnable: caller is not owner nor approved");
		
		if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
		
		if (_tokenReverses[_msgSender()] != 0) {
            delete _tokenReverses[_msgSender()];
        }
		
		if (_tokenResolvers[tokenId] != address(0)) {
            delete _tokenResolvers[tokenId];
        }
		
		_reset(tokenId);

        _burn(tokenId);
    }

    function setOwner(address to, uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        _transfer(ownerOf(tokenId), to, tokenId);
    }
	
	/**
     * Begin: set and get Reverses
     */
	function reverseOf(address account) public view returns (string memory){
        uint256 tokenId = _tokenReverses[account];
        require(tokenId != 0, 'ReverseResolver: REVERSE_RECORD_IS_EMPTY');
        require(_isApprovedOrOwner(account, tokenId), 'ReverseResolver: ACCOUNT_IS_NOT_APPROVED_OR_OWNER');
        return _tokenURIs[tokenId];
    }
	
	function setReverse(uint256 tokenId) public {
        address _sender = _msgSender();
        require(_isApprovedOrOwner(_sender, tokenId), 'ReverseResolver: SENDER_IS_NOT_APPROVED_OR_OWNER');
        _tokenReverses[_sender] = tokenId;
    }
	
	function removeReverse() public {
        address _sender = _msgSender();
        uint256 tokenId = _tokenReverses[_sender];
        require(tokenId != 0, 'ReverseResolver: REVERSE_RECORD_IS_EMPTY');
        delete _tokenReverses[_sender];
    }
	/**
     * End: set and get Reverses
     */
	 
	/**
	* Begin set and get Resolver
	**/
	
	function setResolver(uint256 tokenId, address resolver) external onlyApprovedOrOwner(tokenId) {
        _setResolver(tokenId, resolver);
    }

    function resolverOf(uint256 tokenId) external view returns (address) {
		if (_exists(tokenId) == false){
			return address(0);
		}
		address resolver = _tokenResolvers[tokenId];
        if (resolver == address(0)){
			resolver = address(this);
		}
        return resolver;
    }
	
	function removeResolver(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        require(tokenId != 0, 'ReverseResolver: REVERSE_RECORD_IS_EMPTY');
        delete _tokenResolvers[tokenId];
    }
    
	function _setResolver(uint256 tokenId, address resolver) internal {
        require (_exists(tokenId));
        _tokenResolvers[tokenId] = resolver;
    }
	/**
     * End:Resolver
     */

	/**
     * Begin: Subdomain
     */
    function registerSubDomain(address to, uint256 tokenId, string memory sub) external 
        onlyApprovedOrOwner(tokenId) 
    {
        _safeMintSubDomain(to, tokenId, sub, "");
    }
	
    function burnSubDomain(uint256 tokenId, string memory sub) external onlyApprovedOrOwner(tokenId) 
	{
        _burnSubDomain(tokenId, sub);
    }
	
	function _safeMintSubDomain(address to, uint256 tokenId, string memory sub, bytes memory _data) internal {
		require(to != address(0));
        require (bytes(sub).length != 0);
        require (StringUtil.dotCount(sub) == 0);
        require (_exists(tokenId));
		
		string memory _sub = StringUtil.toLower(sub);
		
        bytes memory _newUri = abi.encodePacked(_sub, ".", _tokenURIs[tokenId]);
		
		uint256 _newTokenId = genTokenId(string(_newUri));

        uint256 count = StringUtil.dotCount(_tokenURIs[tokenId]);
		
        if (count == 1) 
		{
            _subDomains[tokenId].add(_newTokenId);
        }

        if (bytes(_data).length != 0) {
            _safeMint(to, _newTokenId, _data);
        } else {
            _safeMint(to, _newTokenId);
        }
        
        _setTokenURI(_newTokenId, string(_newUri));

        emit NewURI(_newTokenId, string(_newUri));
    }
	
	function _burnSubDomain(uint256 tokenId, string memory sub) internal {
        string memory _sub = StringUtil.toLower(sub);
		
        bytes memory _newUri = abi.encodePacked(_sub, ".", _tokenURIs[tokenId]);
		
		uint256 _newTokenId = genTokenId(string(_newUri));
        // remove sub tokenIds itself
        _subDomains[tokenId].remove(_newTokenId);
		
		if (bytes(_tokenURIs[_newTokenId]).length != 0) {
            delete _tokenURIs[_newTokenId];
        }
		
        super._burn(_newTokenId);
    }

	function subTokenIdCount(uint256 tokenId) public view returns (uint256) {
        require (_exists(tokenId));
        return _subDomains[tokenId].length();
    }
	
	function subTokenIdByIndex(uint256 tokenId, uint256 index) public view returns (uint256) {
        require (subTokenIdCount(tokenId) > index);
        return _subDomains[tokenId].at(index);
    }
	/**
     * End:Subdomain
     */

	/**
     * Begin: System
     */
	function genTokenId(string memory label) public pure returns(uint256)  {
        require (bytes(label).length != 0);
        return uint256(keccak256(abi.encodePacked(label)));
    }

    
	function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
	
	/**
     * End: System
     */
	/**
     * Begin: working with metadata like: avatar, cover, email, phone, address, social ...
     */
	function set(
        string calldata key,
        string calldata value,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId)  {
        _set(key, value, tokenId);
    }

    function setMany(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId)  {
        _setMany(keys, values, tokenId);
    }

    function setByHash(
        uint256 keyHash,
        string calldata value,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId)  {
        _setByHash(keyHash, value, tokenId);
    }

    function setManyByHash(
        uint256[] calldata keyHashes,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId)  {
        _setManyByHash(keyHashes, values, tokenId);
    }

    function reconfigure(
        string[] calldata keys,
        string[] calldata values,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(tokenId) {
        _reconfigure(keys, values, tokenId);
    }

    function reset(uint256 tokenId) external override onlyApprovedOrOwner(tokenId) {
        _reset(tokenId);
    }
	/**
     * End: metadata
     */
}