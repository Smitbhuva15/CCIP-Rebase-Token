// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract RebaseToken is ERC20, Ownable, AccessControl {
    uint256 private s_intrestRate = 5e10;
    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE=keccak256(" MINT_AND_BURN_ROLE");
    mapping(address => uint256) public s_userInterestRate;
    mapping(address => uint256) public s_userLastUpdatedAtTimestamp;

    event InterestRateSet(uint256 newInterestRate);
    error RebaseToken__InterestRateCanOnlyIncrease(
        uint256 currentInterestRate,
        uint256 proposedInterestRate
    );

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {
         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
   
    function grantMintAndBurnRole(address _account) external onlyOwner{
         _grantRole(MINT_AND_BURN_ROLE, _account);
    } 

 
    function setIntrest(uint256 newInterestRate) external onlyOwner{
        if (newInterestRate < s_intrestRate) {
            revert RebaseToken__InterestRateCanOnlyIncrease(
                s_intrestRate,
                newInterestRate
            );
        }
        s_intrestRate = newInterestRate;
        emit InterestRateSet(newInterestRate);
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address user) internal view returns(uint256){
         uint256 lastUpdateTimestamp = s_userLastUpdatedAtTimestamp[user];
      
        if (lastUpdateTimestamp == 0) {
  
            lastUpdateTimestamp = block.timestamp;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTimestamp;

      
        uint256 interestPart = s_userInterestRate[user] * timeElapsed;
       return 1+interestPart;

    }

    function balanceOf(address user) public view override returns (uint256){
      uint256 principalBalance = super.balanceOf(user);

      if (principalBalance == 0) {
            return 0;
        }

          return (principalBalance *  _calculateUserAccumulatedInterestSinceLastUpdate(user)) / PRECISION_FACTOR;
    }

    function _mintAccruedInterest(address user) internal {
        uint256 principalBalance = super.balanceOf(user);
        uint256 totalBalanceWithInterest = balanceOf(user);
        uint256 interestToMint = totalBalanceWithInterest - principalBalance;

        _mint( user, interestToMint);

        s_userLastUpdatedAtTimestamp[user] = block.timestamp;
    }

    function mint(address _to, uint256 _amount) external onlyRole( MINT_AND_BURN_ROLE){
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_intrestRate;
        _mint(_to, _amount);
    }

    

    function burn(address _from,uint256 _amount) external onlyRole( MINT_AND_BURN_ROLE){
        if(_amount==type(uint256).max){
        _amount=balanceOf(_from);
        }
           _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }


    function transfer(address recipient,uint256 _amount) public override returns (bool) {
       _mintAccruedInterest(msg.sender);
       _mintAccruedInterest(recipient);
       if(_amount==type(uint256).max){
        _amount=balanceOf(msg.sender);
       }
       if(balanceOf(recipient)==0){
        s_userInterestRate[recipient]=s_userInterestRate[msg.sender];
       }

       return super.transfer(recipient,_amount);
    }

      function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    function getuserIntrestRate(address user) public view returns(uint256){
      return  s_userInterestRate[user];
    }
}
