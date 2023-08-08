// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the Codex Name Service
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({Codex}).
 *
 */
interface IDomainRegistrar {
    /**
     * @dev Register a domain under top level domain
     * @param to Address to mint
     * @param domain New domain name
     * @param tld Top level domain for domain
     */
    function registerDomain(address to, string memory domain, string memory tld) external;
}