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

    function SetUp() external {

         vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        valut = new Valut(address(rebaseToken));
        rebaseToken.grantMintAndBurnRole(address(valut));

        // (bool success,)=payable(address(valut)).call{value:1e18}("");

        vm.stopPrank();
    }

    function testDepositLinear(uint256 amount) external{
 
        amount=bound(amount, 1e5,type(uint256).max);

        vm.startPrank(user);
        vm.deal(user, amount);

        vm.stopPrank();

    }
}
