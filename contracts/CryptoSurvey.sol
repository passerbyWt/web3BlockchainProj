// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CryptoSurvey is Ownable{
    using SafeERC20 for IERC20;
    IERC20 public cskToken;
    
    
    

    struct Survey {
        string name;
        bool isActive;
        uint256 reward;
        bool isLotto;
        uint256 userCount;
    }

    uint256 countSurveys=0;

    mapping(uint256 => Survey) private _surveys;
    mapping(uint256 => mapping(uint256 => address)) private _users;
    //surveyId->usersMapping    userId->user

    

    

    
    constructor(address tokenAddress) {
        cskToken = IERC20(tokenAddress);
    }

    function getSurveyCount() public view returns (uint256) {

        return countSurveys;
    }


    function getSurvey(uint256 id) external view returns (Survey memory){

        return _surveys[id];
    }

    function createSurvey(string memory pName,bool pIsLotto, uint256 pReward) public returns (uint256){
        countSurveys++;

        _surveys[countSurveys] = Survey({
            name: pName,
            isActive: true,
            reward: pReward,
            isLotto: pIsLotto,
            userCount:0
        });
        return countSurveys;
    }

    function report2Survey(uint256 surveyId) public {
        address reporter = _msgSender();
        _surveys[surveyId].userCount++;
        uint256 uId=_surveys[surveyId].userCount;
        _users[surveyId][uId]=reporter;


        cskToken.safeIncreaseAllowance(reporter, _surveys[surveyId].reward);

       
    }

    function claimReward(uint256 surveyId) public onlyOwner {
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

    function random(uint number) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
            msg.sender))) % number;
    }
}

