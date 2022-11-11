// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contract inspired from https://github.com/pancakeswap/lottery-contract/tree/master/contracts
// TO DO: Think about which test blockchain to load our data on so we can acutally use some of 
// the package such as the CRF for randomness

interface IRandomNumGenerator {
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
    function viewRandomResult() external view returns (uint256);
}

// this fumction is pointless but will be switched out later
contract RandomNumGenerator is IRandomNumGenerator{
    uint256 randomResult;

    function getRandomNumber(uint256 _seed) external override {
        randomResult = _seed;
    }

    function viewLatestLotteryId() external view override returns (uint256) {
        return randomResult;
    }

    function viewRandomResult() external view override returns (uint256){
        return randomResult;
    }
}

contract CovidLotteryTracker {
    using SafeERC20 for IERC20;
    
    enum Status {
        Pending, 
        Open, 
        Close,
        Claimable
    }
    
    struct responder {
        bool result;
        bool responded;
    }

    struct Lottery {
        Status status;
        uint startingLotteryAmt;
        uint256 startTime;
        uint256 endTime;
        address[]lotteryPool;
        uint256 winnerNumber;
    }

    IERC20 public lottoToken;
    RandomNumGenerator public randomGen;
    address[] lotteryPool;
    mapping(uint256 => Lottery) private _lotteries;
    uint256 public currentLotteryId;

    mapping(address => responder) public responses;

    // need a way to allow users to define the time which the lotter start or stops
    uint256 public constant MIN_LENGTH_LOTTERY = 2 minutes;
    uint256 public constant MAX_LENGTH_LOTTERY = 2 minutes;
    uint256 public constant MAX_TREASURY_FEE = 300; // 3%
    uint public counter = 1;
    uint public randomNum; 


    // data to store on the blockchain
    event LotteryClose(uint256 indexed lotteryId);
    event LotteryOpen(
        uint256 indexed lotteyID,
        uint256 startingLotteryAmt,
        uint256 startTime,
        uint256 endTime

    );

    constructor(address _lottoTokenAddress, address _randomGeneratorAddress) {
        lottoToken = IERC20(_lottoTokenAddress);
        randomGen  = RandomNumGenerator(_randomGeneratorAddress);
    }
    
    // need to take care of other conditions, maybe different way to enter 
    // into the lottery
    function pushCovidCondition(bool res, uint lotteryID) public {
        require(
            !responses[msg.sender].responded,
            "the person already responded"
        );
        

        // currently just storing one response, but we can add more to this later
        responses[msg.sender].responded = true;
        responses[msg.sender].result = res;

        // create the lottery pool for the lotter. 
        _lotteries[lotteryID].lotteryPool.push(msg.sender);
    }

    function startLottery(uint256 _startingLotteryAmt, uint256 _endTime, uint256 _treasuryFee) external {
        require(
            ((_endTime - block.timestamp) > MIN_LENGTH_LOTTERY) && ((_endTime - block.timestamp) < MAX_LENGTH_LOTTERY), 
            "Lottery length outside of range"
        );
        
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high.");
        
        
        currentLotteryId++;

        _lotteries[currentLotteryId] = Lottery({
            status: Status.Open,
            startingLotteryAmt: _startingLotteryAmt,
            startTime: block.timestamp,
            endTime: _endTime, 
            lotteryPool: lotteryPool,
            winnerNumber: 0

        });

        emit LotteryOpen(currentLotteryId, block.timestamp, _endTime, _startingLotteryAmt);
    }

    function closeLottery(uint256 _lotteryId) external {
        require(_lotteries[_lotteryId].status == Status.Open, "Lottery not open");
        require(block.timestamp > _lotteries[_lotteryId].endTime, "Lotter not over");
        
        randomGen.getRandomNumber(random(_lotteryId));
        _lotteries[_lotteryId].status = Status.Close;

        emit LotteryClose(_lotteryId);

    }

    // this piece of code is obtain from https://stackoverflow.com/questions/48848948/how-to-generate-a-random-number-in-solidity
    // we need to change the randome number generator to secure offchain 
    function random(uint256 _lotteryId) public returns (uint) {
        counter ++;
        randomNum = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _lotteryId, counter)));

        return randomNum;
    }



    function drawAddressAndMakeLotteryClaimable(uint256 _lotteryId) external {
        require(_lotteries[_lotteryId].status == Status.Close, "Lottery not close");

        uint256 winnerNumber = randomGen.viewRandomResult() % _lotteries[_lotteryId].lotteryPool.length;

        // TO DO: need to add here how to handle the funds, currently we can just test the lottery

        // update the lottery info 
        _lotteries[_lotteryId].winnerNumber = winnerNumber;
        _lotteries[_lotteryId].status = Status.Claimable;
    }

    function claimRe

    // function viewCurrentLotteryId() external view override return (uint256) {
    //     return currentLotteryId;
    // }

    // // function drawFinalWinner() {
        
    // // }



}

