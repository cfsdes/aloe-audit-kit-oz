// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {MAX_RATE, MAX_LEVERAGE} from 
"src/libraries/constants/Constants.sol";

import "src/Lender.sol";
import "src/RateModel.sol";

import {FactoryForLenderTests} from "../Utils.sol";

contract LenderTest is Test {
    using stdStorage for StdStorage;

    ERC20 asset;

    Lender lender;

    function setUp() public {
        FactoryForLenderTests factory = new FactoryForLenderTests(new 
RateModel(), ERC20(address(0)));

        asset = new MockERC20("Token", "TKN", 18);
        lender = factory.deploySingleLender(asset);
    }

    function testFail_flash_and_deposit() public {
        Attacker attacker = new Attacker(address(asset), address(lender));

        // Deposit
        deal(address(asset), address(lender), 1e18);
        lender.deposit(1e18, address(this));

        // Calls flash()
        vm.startPrank(address(attacker));
        lender.flash(100, attacker, bytes(""));
        vm.stopPrank();
    }
}


// Attacker contract
contract Attacker is IFlashBorrower {
    Lender lender;
    ERC20 asset;

    constructor(address _asset, address _lender){
        lender = Lender(_lender);
        asset = MockERC20(_asset);
    }

    function onFlashLoan(address initiator, uint256 amount, bytes calldata 
data) external {
        require(asset.balanceOf(address(this)) >= amount, "Assets not 
transfered");
        asset.approve(address(lender), 100);
        lender.deposit(100, address(this), 0);
    }
}
