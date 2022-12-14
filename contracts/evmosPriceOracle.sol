// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ensdomains/ens-contracts/contracts/ethregistrar/StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/PriceOracle.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

// evmos PriceOracle sets a price in evmos Wei per seconds based on domain length
contract evmosPriceOracle is Ownable, PriceOracle {
    using StringUtils for *;

    // Rent in base price per day by length. Element 0 is for 1-length names, and so on.
    uint[] public rentPrices;

    event RentPriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string,uint256,uint256)") ^ keccak256("premium(string,uint256,uint256)"));

    constructor(uint[] memory _rentPrices) {
        setPrices(_rentPrices);
    }

    function price(string calldata name) external view override returns (uint) {
        uint len = name.strlen();
        if (len > rentPrices.length) {
            len = rentPrices.length;
        }
        require(len > 0);
        return rentPrices[len - 1];
    }
    
    /**
     * @dev Sets rent prices.
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in evmos Wei per seconds.
     */
    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }


    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}