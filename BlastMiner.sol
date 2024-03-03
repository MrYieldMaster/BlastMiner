/**
 *Submitted for verification by DevAudits 03/02/24
 
*/

/**

$$$$$$$\  $$\                       $$\     $$\      $$\ $$\                               
$$  __$$\ $$ |                      $$ |    $$$\    $$$ |\__|                              
$$ |  $$ |$$ | $$$$$$\   $$$$$$$\ $$$$$$\   $$$$\  $$$$ |$$\ $$$$$$$\   $$$$$$\   $$$$$$\  
$$$$$$$\ |$$ | \____$$\ $$  _____|\_$$  _|  $$\$$\$$ $$ |$$ |$$  __$$\ $$  __$$\ $$  __$$\ 
$$  __$$\ $$ | $$$$$$$ |\$$$$$$\    $$ |    $$ \$$$  $$ |$$ |$$ |  $$ |$$$$$$$$ |$$ |  \__|
$$ |  $$ |$$ |$$  __$$ | \____$$\   $$ |$$\ $$ |\$  /$$ |$$ |$$ |  $$ |$$   ____|$$ |      
$$$$$$$  |$$ |\$$$$$$$ |$$$$$$$  |  \$$$$  |$$ | \_/ $$ |$$ |$$ |  $$ |\$$$$$$$\ $$ |      
\_______/ \__| \_______|\_______/    \____/ \__|     \__|\__|\__|  \__| \_______|\__|  

*/

/**

BlastMining: A decentralized platform for ETH Mining on the Blast Network

 Website: https://blastmining.xyz

 Whitepaper: https://docs.blastmining.xyz

 Telegram : https://t.me/BlastMining

 Layer 2 : https://blastexplorer.io/


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlastMiner {
    // Constants for staking and penalties
    uint256 private constant STAKING_REWARD_PERCENTAGE = 5; // 5% per year
    uint256 private constant EMERGENCY_WITHDRAWAL_PENALTY = 15; // 15%
    uint256 private constant SECONDS_IN_A_YEAR = 31536000;

    uint256 private EGGS_TO_HATCH_1MINERS = 2592000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    bool private initialized = false;
    address public ceoAddress;
    address public ceoAddress2;

    mapping(address => uint256) public hatcheryMiners;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public marketEggs;

    // New variables for staking
    mapping(address => uint256) public stakedEggs;
    mapping(address => uint256) public stakeTimestamp;

    constructor() {
        ceoAddress = msg.sender;
        ceoAddress2 = address(0xb0B1EDD7479Fe09A95c4228d8E88c1A7A3aaa072);
    }

    function hatchEggs(address ref) public {
        require(initialized);
        if (ref == msg.sender) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = eggsUsed / EGGS_TO_HATCH_1MINERS;
        hatcheryMiners[msg.sender] += newMiners;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        // send referral eggs
        claimedEggs[referrals[msg.sender]] += eggsUsed / 10;

        // boost market to nerf miners hoarding
        marketEggs += eggsUsed / 5;
    }

    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs += hasEggs;
        payable(ceoAddress).transfer(fee / 4);
        payable(ceoAddress2).transfer(fee - (fee / 4));
        payable(msg.sender).transfer(eggValue - fee);
    }

    function buyEggs(address ref) public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, address(this).balance - msg.value);
        eggsBought -= devFee(eggsBought);
        uint256 fee = devFee(msg.value);
        payable(ceoAddress).transfer(fee / 4);
        payable(ceoAddress2).transfer(fee - (fee / 4));
        claimedEggs[msg.sender] += eggsBought;
        hatchEggs(ref);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
    }

    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth, address(this).balance);
    }

    function seedMarket() public payable {
        require(marketEggs == 0);
        initialized = true;
        marketEggs = 259200000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners() public view returns (uint256) {
        return hatcheryMiners[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return claimedEggs[msg.sender] + getEggsSinceLastHatch(msg.sender);
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1MINERS, block.timestamp - lastHatch[adr]);
        return secondsPassed * hatcheryMiners[adr];
    }

    function stakeEggs(uint256 amount) public {
        require(getMyEggs() >= amount, "Not enough eggs");
        claimedEggs[msg.sender] -= amount;
        stakedEggs[msg.sender] += amount;
        stakeTimestamp[msg.sender] = block.timestamp;
    }

    function unstakeEggs() public {
        uint256 stakedAmount = stakedEggs[msg.sender];
        require(stakedAmount > 0, "No staked eggs");

        uint256 reward = calculateStakingReward(msg.sender);
        stakedEggs[msg.sender] = 0;
        claimedEggs[msg.sender] += stakedAmount + reward;
    }

    function emergencyWithdraw() public {
        uint256 stakedAmount = stakedEggs[msg.sender];
        require(stakedAmount > 0, "No staked eggs");

        uint256 penaltyAmount = stakedAmount * EMERGENCY_WITHDRAWAL_PENALTY / 100;
        uint256 withdrawalAmount = stakedAmount - penaltyAmount;
        stakedEggs[msg.sender] = 0;

        payable(msg.sender).transfer(withdrawalAmount);
    }

    function calculateStakingReward(address user) public view returns (uint256) {
        uint256 stakedDuration = block.timestamp - stakeTimestamp[user];
        uint256 stakedAmount = stakedEggs[user];
        uint256 annualReward = stakedAmount * STAKING_REWARD_PERCENTAGE / 100;
        return (annualReward * stakedDuration) / SECONDS_IN_A_YEAR;
    }

    // Utility functions
    function getStakedEggs(address user) public view returns (uint256) {
        return stakedEggs[user];
    }

    function devFee(uint256 amount) private pure returns (uint256) {
        return amount * 4 / 100; // 4% dev fee
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

}