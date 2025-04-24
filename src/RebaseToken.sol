// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RebaseToken is ERC20 {
    uint256 private s_intrestRate = 5e10;
uint256 private constant PRECISION_FACTOR = 1e18;
    mapping(address => uint256) public s_userInterestRate;
    mapping(address => uint256) public s_userLastUpdatedAtTimestamp;

    event InterestRateSet(uint256 newInterestRate);
    error RebaseToken__InterestRateCanOnlyIncrease(
        uint256 currentInterestRate,
        uint256 proposedInterestRate
    );

    constructor() ERC20("Rebase Token", "RBT") {}

    function setIntrest(uint256 newInterestRate) external {
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

        s_userLastUpdatedAtTimestamp[user] = block.timestamp;
    }

    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_intrestRate;
        _mint(_to, _amount);
    }
}
