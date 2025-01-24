// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    mapping (address => uint256) public balances;
    uint256 public constant threshold = 1 ether;

    event Stake(address staker, uint256 amount);

    uint256 public deadline = block.timestamp + 30 seconds;
    bool public openForWithdraw = false;

    modifier notCompleted() {
        require(exampleExternalContract.completed() == false, "ExternalContract has been completed!");
        _;
    }

    modifier notExecuted() {
        bool isExecuted = openForWithdraw || exampleExternalContract.completed();
        require(isExecuted == false, "Already executed!");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    function stake() public payable notExecuted {
        address sender = msg.sender;
        uint256 amount = msg.value;
        balances[sender] += amount;
        emit Stake(sender, amount);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notExecuted {
        uint256 time = timeLeft();
        require(time == 0, "Deadline not met yet!");

        uint256 totalBalance = address(this).balance;

        if ( totalBalance >= threshold) {
            exampleExternalContract.complete{value: totalBalance}();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public notCompleted {
        require(openForWithdraw, "Not yet open for withdraw");

        uint256 userBalance = balances[msg.sender];
        balances[msg.sender] = 0;

        if (userBalance > 0) {
            (bool sent, bytes memory _data) =  msg.sender.call{value: userBalance}("");
            require(sent, "Failed to send Ether");
        }
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}
