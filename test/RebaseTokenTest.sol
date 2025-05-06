// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

import {RebaseToken} from "../src/RebaseToken.sol";

import {Valut} from "../src/Valut.sol";

contract RebaseTokenTest is Test {

    RebaseToken private rebaseToken;
    Valut private valut;
    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() external {

         vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        valut = new Valut(address(rebaseToken));
        rebaseToken.grantMintAndBurnRole(address(valut));

        (bool success,)=payable(address(valut)).call{value:1e18}("");

        vm.stopPrank();
    }

    function testDepositLinear(uint256 amount) external{
 
        amount=bound(amount, 1e5,type(uint256).max);

        vm.startPrank(user);
        vm.deal(user, amount);

        valut.deposite{value:amount}();

        uint256 initialBalance=rebaseToken.balanceOf(user);
        assertEq(initialBalance,amount);

        vm.warp(block.timestamp+1 hours);
          uint256 middleBalance =rebaseToken.balanceOf(user);
          assertGe(middleBalance, initialBalance);

          
        vm.warp(block.timestamp+1 hours);
          uint256 secondBalance =rebaseToken.balanceOf(user);
          assertGe(secondBalance, middleBalance);

          assert(secondBalance-middleBalance==middleBalance-initialBalance);

        vm.stopPrank();

    }
}
