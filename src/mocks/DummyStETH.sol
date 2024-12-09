// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {UnstructuredStorage} from "./UnstructuredStorage.sol";

contract DummyStETH is ERC20, Ownable {
    using UnstructuredStorage for bytes32;

    // Storage positions as defined in the L2 contract
    bytes32 public constant TOTAL_SHARES_POSITION = 0xe3b4b636e601189b5f4c6742edf2538ac12bb61ed03e6da26949d69838fa447e;
    bytes32 public constant BUFFERED_ETHER_POSITION = 0xed310af23f61f96daefbcd140b306c0bdbf8c178398299741687b90e794772b0;
    bytes32 public constant CL_BALANCE_POSITION = 0xa66d35f054e68143c18f32c990ed5cb972bb68a68f500cd2dd3a16bbf3686483;
    bytes32 public constant DEPOSITED_VALIDATORS_POSITION = 0xe6e35175eb53fc006520a2a9c3e9711a7c00de6ff2c32dd31df8c5a24cac1b5c;
    bytes32 public constant CL_VALIDATORS_POSITION = 0x9f70001d82b6ef54e9d3725b46581c3eb9ee3aa02b941b6aa54d678a9ca35b10;

    uint256 private constant DEPOSIT_SIZE = 32 ether;

    mapping (address => uint256) private shares;

    constructor() ERC20("Dummy Lido Staked Ether", "stETH") Ownable(msg.sender) {
        // Initialize with some default values
        TOTAL_SHARES_POSITION.setStorageUint256(1_000_000 ether);
        BUFFERED_ETHER_POSITION.setStorageUint256(100 ether);
        CL_BALANCE_POSITION.setStorageUint256(1000 ether);
        DEPOSITED_VALIDATORS_POSITION.setStorageUint256(32); // Assuming 32 validators deposited
        CL_VALIDATORS_POSITION.setStorageUint256(30); // Assuming 30 validators active   
    }

    function balanceOf(address account) public view override returns (uint256) {
        return getPooledEthByShares(shares[account]);
    }

    // Method to simulate L1 storage read for specific positions
    function readStorageAtPosition(bytes32 position) external view returns (uint256) {
        return position.getStorageUint256();
    }

    // Admin methods to adjust simulated state
    function setTotalShares(uint256 _shares) external onlyOwner {
        TOTAL_SHARES_POSITION.setStorageUint256(_shares);
    }

    function setBufferedEther(uint256 amount) external onlyOwner {
        BUFFERED_ETHER_POSITION.setStorageUint256(amount);
    }

    function setClBalance(uint256 balance) external onlyOwner {
        CL_BALANCE_POSITION.setStorageUint256(balance);
    }

    function setValidators(uint256 depositedValidators, uint256 clValidators) external onlyOwner {
        require(depositedValidators >= clValidators, "Invalid validator count");
        DEPOSITED_VALIDATORS_POSITION.setStorageUint256(depositedValidators);
        CL_VALIDATORS_POSITION.setStorageUint256(clValidators);
    }

    // Mock methods to simulate stETH behavior
    function getTotalPooledEther() public view returns (uint256) {
        return 
            BUFFERED_ETHER_POSITION.getStorageUint256() + 
            CL_BALANCE_POSITION.getStorageUint256() + 
            getTransientBalance();
    }

    function getTransientBalance() public view returns (uint256) {
        uint256 depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        uint256 clValidators = CL_VALIDATORS_POSITION.getStorageUint256();
        
        require(depositedValidators >= clValidators, "Invalid validator state");
        return (depositedValidators - clValidators) * DEPOSIT_SIZE;
    }

    function getSharesByPooledEth(uint256 _eth) public view returns (uint256) {
        if (getTotalPooledEther() == 0) return _eth;
        return (_eth * TOTAL_SHARES_POSITION.getStorageUint256()) / getTotalPooledEther();
    }

    function getPooledEthByShares(uint256 _shares) public view returns (uint256) {
        uint256 totalShares = TOTAL_SHARES_POSITION.getStorageUint256();
        if (totalShares == 0) return 0;
        return (_shares * getTotalPooledEther()) / totalShares;
    }

    // Dummy mint and burn for testing
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        uint256 sharesAmount = getSharesByPooledEth(amount);
        shares[to] = sharesAmount;
        TOTAL_SHARES_POSITION.setStorageUint256(TOTAL_SHARES_POSITION.getStorageUint256() + sharesAmount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}