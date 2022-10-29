// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// contract inspired from https://github.com/pancakeswap/lottery-contract/tree/master/contracts


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
    
    enum Status {
        Pending, 
        Open, 
        Close
    }
    
    struct responder {
        bool result;
        bool responded;
    }

    struct Lottery {
        Status status;
    }

    IERC20 public lottoToken;
    RandomNumGenerator public randomGen;
    address[] public lotteryPool;
    mapping(uint256 => Lottery) private _lotteries;

    mapping(address => responder) public responses;

    // need a way to allow users to define the time which the lotter start or stops
    uint256 public constant MIN_LENGTH_LOTTERY = 2 minutes;
    uint256 public constant MAX_LENGTH_LOTTERY = 2 minutes;
    uint256 public constant MAX_TREASURY_FEE = 300; // 3%


    
    constructor(address _lottoTokenAddress, address _randomGeneratorAddress) {
        lottoToken = IERC20(_lottoTokenAddress);
        randomGen  = RandomNumGenerator(_randomGeneratorAddress);
    }
    
    // need to take care of other conditions, maybe different way to enter 
    // into the lottery
    function pushCovidCondition(bool res) public {
        require(
            !responses[msg.sender].responded,
            "the person already responded"
        );
        
        responses[msg.sender].responded = true;
        responses[msg.sender].result = res;

        lotteryPool.push(msg.sender);
    }

    function startLottery(uint256 _endTime, uint256 _treasuryFee) {
        require(
            ((_endTime - block.timestamp) > MIN_LENGTH_LOTTERY) && ((_endTime - block.timestamp) < MAX_LENGTH_LOTTERY), 
            "Lottery length outside of range"
        );


    }

    // function drawFinalWinner() {
        
    // }



}

