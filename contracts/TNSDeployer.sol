// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import {INameWrapper, PublicResolver} from '@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol';
import '@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol';
import '@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol';
import {NameResolver, ReverseRegistrar} from '@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol';

// Construct a set of test ENS contracts.
contract ENSDeployer {
  bytes32 public constant TLD_LABEL = keccak256('tron');
  bytes32 public constant RESOLVER_LABEL = keccak256('resolver');
  bytes32 public constant REVERSE_REGISTRAR_LABEL = keccak256('reverse');
  bytes32 public constant ADDR_LABEL = keccak256('addr');

  ENSRegistry public tns;
  FIFSRegistrar public fifsRegistrar;
  ReverseRegistrar public reverseRegistrar;
  PublicResolver public publicResolver;

  function namehash(bytes32 node, bytes32 label) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(node, label));
  }

  constructor() public {
    tns = new ENSRegistry();
    publicResolver = new PublicResolver(tns, INameWrapper(address(0)));

    // Set up the resolver
    bytes32 resolverNode = namehash(bytes32(0), RESOLVER_LABEL);

    tns.setSubnodeOwner(bytes32(0), RESOLVER_LABEL, address(this));
    tns.setResolver(resolverNode, address(publicResolver));
    publicResolver.setAddr(resolverNode, address(publicResolver));

    // Create a FIFS registrar for the TLD
    fifsRegistrar = new FIFSRegistrar(tns, namehash(bytes32(0), TLD_LABEL));

    tns.setSubnodeOwner(bytes32(0), TLD_LABEL, address(fifsRegistrar));

    // Construct a new reverse registrar and point it at the public resolver
    reverseRegistrar = new ReverseRegistrar(
      ens,
      NameResolver(address(publicResolver))
    );

    // Set up the reverse registrar
    tns.setSubnodeOwner(bytes32(0), REVERSE_REGISTRAR_LABEL, address(this));
    tns.setSubnodeOwner(
      namehash(bytes32(0), REVERSE_REGISTRAR_LABEL),
      ADDR_LABEL,
      address(reverseRegistrar)
    );
  }
}