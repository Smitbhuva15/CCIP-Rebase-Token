// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import './interfaces/IRebaseToken.sol';


contract Valut{


    IRebaseToken immutable private i_rebaseToken;

    event Deposite(address indexed sender,uint256 _amount);
    event Redeem(address indexed sender,uint256 _amount);

    error Vault_RedeemFailed();

    constructor(address rebaseToken){
       i_rebaseToken=IRebaseToken(rebaseToken);
    }
    
    function deposite() payable external{
        uint256 amountToMint=msg.value;

        if(msg.value==0){
           revert("Deposit amount must be greater than zero");
        }


        i_rebaseToken.mint(msg.sender,amountToMint);
       emit Deposite(msg.sender, amountToMint);
    }

    function redeem(uint256 _amount) external {
         if (_amount == 0) {
            revert("Redeem amount must be greater than zero");
        }

        i_rebaseToken.burn(msg.sender,_amount);

       (bool success,)= payable(msg.sender).call{value:_amount}("");

       if(!success){
        revert Vault_RedeemFailed();
       }

       emit Redeem(msg.sender,_amount);

    }

    receive() external payable{}
}