// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CryptoSurvey is Ownable{
    using SafeERC20 for IERC20;
    IERC20 public cskToken;
    
    uint256 public signUpReward = 10 * (10 * 18);
    mapping(address => user) userPool;
    uint256 public userSignUpCount;

    // Variable to ensure users does not malicously signup many accounts
    uint256 public signUpRewardLockTime = 1 days;
    uint256 public userSignUpCountLockLimit = 3;
    uint256 public nextAccessTime;
    uint256 public userSignUpCountLockCount;
    uint256 public lastUserLimitTime;

    event Deposit(address indexed from, uint256 indexed amount);
    event Withdraw(address indexed to, uint256 indexed amount);

    struct user {
        uint256 dataQualityScore;
        bool isValue;
    }

    struct Survey {
        string name;
        bool isActive;
        uint256 reward;
        bool isLotto;
        uint256 enteranceFee;
        uint256 surveyEndTime;
        uint256 userCount;
    }

    uint256 countSurveys=0;

    mapping(uint256 => Survey) private _surveys;
    mapping(uint256 => mapping(uint256 => address)) private _users;
    //surveyId->usersMapping    userId->user
    
    constructor(address tokenAddress) {
        cskToken = IERC20(tokenAddress);
    }

    // 
    function requestignUpReward() public {
        require(msg.sender != address(0), "Address cannot be zero.");
        // require(cskToken.balanceOf(address(this)) >= signUpReward, "Insufficient token in CryptoSurvey contract");
        require(block.timestamp >  nextAccessTime, "Too many users signup.");
        require(userPool[msg.sender].isValue == false, "User already signup");
        
        userPool[msg.sender].dataQualityScore = 1;
        cskToken.transfer(msg.sender, signUpReward);

        // To prevent too many people from signing up to get the reward
        userSignUpCountLockCount += 1;

        if (userSignUpCountLockCount > userSignUpCountLockLimit){
            if (lastUserLimitTime + signUpRewardLockTime > block.timestamp) {
                nextAccessTime = block.timestamp + signUpRewardLockTime;
            }
            lastUserLimitTime = block.timestamp;
            userSignUpCountLockCount = 0;
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return cskToken.balanceOf(address(this));
    }

    function withdraw() external onlyOwner {
        emit Withdraw(msg.sender, cskToken.balanceOf(address(this)));
        cskToken.transfer(msg.sender, cskToken.balanceOf(address(this)));
    }

    function unlockSignUp() external onlyOwner {
        nextAccessTime = 0;
    }    

    function setLockTime(uint256 amtTime, uint256 amtUsers) public onlyOwner {
        signUpRewardLockTime = amtTime * 1 minutes;
        userSignUpCountLockLimit = amtUsers;
    }

    //get the number of surveys
    function getSurveyCount() public view returns (uint256) {

        return countSurveys;
    }

    //get the survey by id
    //ex: countSurveys=10 means there are ten surveys. the ids are 1,2,3,....10
    function getSurvey(uint256 id) external view returns (Survey memory){

        return _surveys[id];
    }

    //create a new survey, id is countSurveys+1
    function createSurvey(string memory pName, 
                        bool pIsLotto, 
                        uint256 pReward, 
                        uint256 surveyDuration, 
                        uint256 enteranceFee) public returns (uint256){
        countSurveys++;

        _surveys[countSurveys] = Survey({
            name: pName,
            isActive: true,
            reward: pReward,
            isLotto: pIsLotto,
            enteranceFee: enteranceFee,
            surveyEndTime: block.timestamp + surveyDuration * 1 minutes,
            userCount:0
        });
        return countSurveys;
    }

    //report to a servey
    function report2Survey(uint256 surveyId) public {
        require(_surveys[surveyId].enteranceFee <= 0, "There is an entrance fee for this survey");
        address reporter = _msgSender();
        _surveys[surveyId].userCount++;
        uint256 uId=_surveys[surveyId].userCount;
        _users[surveyId][uId]=reporter;


        cskToken.safeIncreaseAllowance(reporter, _surveys[surveyId].reward);
    }

    function report2SurveyWithEntranceFee(uint256 surveyId) public payable {
        require(_surveys[surveyId].enteranceFee > 0, "There is no entrance fee for this survey");
        require(msg.value > _surveys[surveyId].enteranceFee, "Enterence amount is lower than requested");
        address reporter = _msgSender();
        _surveys[surveyId].userCount++;
        uint256 uId=_surveys[surveyId].userCount;
        _users[surveyId][uId]=reporter;
        _surveys[surveyId].reward+=_surveys[surveyId].enteranceFee;


        cskToken.safeIncreaseAllowance(reporter, _surveys[surveyId].reward);
    }

    //the owner of this contract can end the survey and give the reward
    function claimReward(uint256 surveyId) public onlyOwner {
        require(block.timestamp > _surveys[surveyId].surveyEndTime, "Survey has not ended");

        if (_surveys[surveyId].isActive){
            if (_surveys[surveyId].isLotto){
                
                uint256 uId=random(_surveys[surveyId].userCount)+1;
                address userAddress=_users[surveyId][uId];
                uint256 amount=_surveys[surveyId].reward;
                
                cskToken.transfer(userAddress, amount);

            }else{
                uint256 amount=uint256(_surveys[surveyId].reward/_surveys[surveyId].userCount);
                for (uint i = 1; i <= _surveys[surveyId].userCount; i++) {
                    address userAddress=_users[surveyId][i];
                    
                    cskToken.transfer(userAddress, amount);
                }

            }
            _surveys[surveyId].isActive=false;
        }
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    //easy version of get random number
    function random(uint number) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
            msg.sender))) % number;
    }
}
