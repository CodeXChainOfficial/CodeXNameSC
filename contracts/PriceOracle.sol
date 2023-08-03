// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This oracle provides the estimated amount of TRX matches for 1 USD.
pragma experimental ABIEncoderV2;

import "./bandchain/Obi.sol";
import "./bandchain/IBridge.sol";
import "./bandchain/IBridgeCache.sol";
import "./bandchain/ResultDecoder.sol";
import "./bandchain/.sol";
import "./utils/SafeMath.sol";


contract PriceOracle {
    using SafeMath for uint256;
    using ResultDecoder for bytes;
    using ParamsDecoder for bytes;
    
    IBridgeCache public bridge;
    IBridge.RequestPacket public req;
    
    uint256 public current_price;

    constructor(IBridgeCache bridge_) public {
        bridge = bridge_;
        
        req.clientId = "tron_testnet";
        req.oracleScriptId = 76;
        // {symbol:"BTC"}
        req.params = hex"00000003545258";
        req.askCount = 4;
        req.minCount = 3;
    }

    // Fetches the latest BTC/USD price value from the bridge contract and saves it to state.
    function setPrice() public {
        IBridge.ResponsePacket memory res = bridge.getLatestResponse(req);
        ResultDecoder.Result memory result = res.result.decodeResult();
        current_price = result.px;
    }
}