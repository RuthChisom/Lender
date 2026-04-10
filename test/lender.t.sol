// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "test/Utils/Utilities.sol";
import "forge-std/Test.sol";

import {Lender} from "src/Lender.sol";

contract LenderTest is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    Lender internal lenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        lenderPool = new Lender();
        vm.label(address(lenderPool), "Side Entrance Lender Pool");

        vm.deal(address(lenderPool), ETHER_IN_POOL);

        assertEq(address(lenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    // you must not touch anything in setup,
    // you must not prank the owner address or the Lender Contract it self.
    // focus on adding your logic to the EXPLOIT START and EXPLOIT END markers
    // you can create a contract if you need to. GOODLUCK!!!
    function testExploit() public {
        /**
         * EXPLOIT START *
         */

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(lenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
