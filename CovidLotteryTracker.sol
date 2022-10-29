// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface RandomNumGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest lotteryId numbers
     */
    function viewLatestLotteryId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint32);
}

contract CovidLotteryTracker {
    using SafeERC20 for IERC20;
    
    struct responder {
        bool result;
        bool responded;
    }

    IERC20 public lottoToken;
    RandomNumGenerator public randomGen;
    address[] public lotteryPool;
    mapping(address => responder) public responses;

    
    constructor(address _lottoTokenAddress, address _randomGeneratorAddress) {
        lottoToken = IERC20(_lottoTokenAddress);
        randomGen  = RandomNumGenerator(_randomGeneratorAddress);
    }
    

    function gotCovidCondition(bool res) public {
        require(
            !responses[msg.sender].responded,
            "the person already responded"
        );
        
        responses[msg.sender].responded = true;
        responses[msg.sender].result = res;

        lotteryPool.push(msg.sender);
    }



}

