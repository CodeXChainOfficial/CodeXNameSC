// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "./bandchain/Obi.sol";
import "./bandchain/IBridge.sol";
import "./bandchain/IBridgeCache.sol";
import "./bandchain/ResultDecoder.sol";
import "./bandchain/ParamsDecoder.sol";
import "./utils/SafeMath.sol";

// This oracle provides the estimated amount of TRX matches for 1 USD.
abstract contract PriceOracle {
    using SafeMath for uint256;
    using ResultDecoder for bytes;
    using ParamsDecoder for bytes;
    
    IBridgeCache public bridge;
    IBridge.RequestPacket public req;
    
    uint256 public current_price;
    uint64 public lastUpdateAt;

    constructor(IBridgeCache bridge_) {
        bridge = bridge_;
        
        req.clientId = "bandteam";
        req.oracleScriptId = 8;
        // {symbol:"TRX"}
        req.params = hex"00000003545258";
        req.askCount = 4;
        req.minCount = 3;
    }

    // Fetches the latest TRX/USD price value from the bridge contract and saves it to state.
    function setPrice() public {
        IBridge.ResponsePacket memory res = bridge.getLatestResponse(req);
        ResultDecoder.Result memory result = res.result.decodeResult();
        current_price = result.rates[14];
        lastUpdateAt = res.resolveTime;
    }

    function getPrice() public view returns(uint256) {
        return current_price;
    }
}