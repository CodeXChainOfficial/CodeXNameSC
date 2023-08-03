// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Obi.sol";

library ParamsDecoder {
    using Obi for Obi.Data;

    struct Params {
        string symbols;
        uint64 multiplier;
    }

    function decodeParams(bytes memory _data)
        internal
        pure
        returns (Params memory result)
    {
        Obi.Data memory data = Obi.from(_data);
        result.symbols = string(data.decodeBytes());
        result.multiplier = data.decodeU64();
    }
}