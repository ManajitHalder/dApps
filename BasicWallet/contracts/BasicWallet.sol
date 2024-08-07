// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

Write a basic wallet with the following features:

1. Only the owner of the contract can withdraw amount
2. Only the owner of the cotract can send some ETH to other account
3. Anyone can send ETH to the owner account
4. Wallet maintains a list of account (name and address) it can send/receive ETH
5. Only the owner can add new accounts to the wallet
6. Only the owner can remove accounts from the wallet
7. Only the owner can edit account details 
8. Maintain transaction history
9. Maintain a list of favourite accounts
10. 

Utility functions:
1. get balance of the account
2.
 
*/

contract BasicWallet {
    // owner address
    address public owner;

    // Mapping to maintain list of account addresses with name of the person for more user-friendly access
    mapping(string => address) private addressList;

    // Transaction struct to represent an individual transaction. 
    // Created to maintain log of all transactions within the contract, including
    // deposit, withdraw, transfer, transferTo for better transparency and auditing.
    struct Transaction {
        address sender;
        address recipient;
        uint256 amount;
        uint256 timestamp;
    }

    // Mapping to store transaction record
    mapping(bytes32 => Transaction) public transactionRecord;

    // event for deposit
    event Deposit(address indexed from, uint256 amount, uint256 timestamp);
    // event for withdrawl
    event Withdraw(address indexed owner, uint256 amount, uint256 timestamp);
    // event for transfer
    event Transfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    // Modifier to restrict access only to owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // Fallback function to receive ETH
    receive() external payable {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    // To receive ether from other contract/addresses
    function deposit() external payable returns (bool) {
        require(msg.value > 0, "Must send some ether");

        // Add a transaction record
        bytes32 txId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        transactionRecord[txId] = Transaction(msg.sender, address(this), msg.value, block.timestamp);

        emit Deposit(msg.sender, msg.value, block.timestamp);

        return true;
    }

    // Withdraw function to withdraw ether by owner only
    function withdraw(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");

        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");

        // Add a transaction record
        bytes32 txId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        transactionRecord[txId] = Transaction(address(this), msg.sender, _amount, block.timestamp);

        emit Withdraw(owner, _amount, block.timestamp);
    }

    // transfer amount to another account
    function transfer(address payable _to, uint256 _amount) public onlyOwner returns (bool) {
        require(address(this).balance >= _amount, "Insufficient balance in the contract");
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Trasfer failed");

        // Add a transaction record
        bytes32 txId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        transactionRecord[txId] = Transaction(address(this), _to, _amount, block.timestamp);

        emit Transfer(address(this), _to, _amount, block.timestamp);

        return success;
    }

    // transfer amount to a address from the addressList retrieved by using name
    function transferTo(string calldata _name, uint256 _amount) public onlyOwner returns (bool) {
        address payable to = payable(getAddress(_name));
        require(address(this).balance > _amount, "Insufficient balance in contract");

        (bool success, ) = to.call{value: _amount}("");
        require(success, "Transfer to address from addressList failed");

        // Add a transaction record
        bytes32 txId = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        transactionRecord[txId] = Transaction(address(this), to, _amount, block.timestamp);

        emit Transfer(address(this), to, _amount, block.timestamp);

        return success;
    }

    // Add an address to the addressList to be maintained in the contract
    function addAddress(string calldata _name, address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        // ensure that _name doesnot exist in the mapping. 
        // If addressList[_name] is equal to address(0), 
        // it means that the key _name does not currently have an associated address in the mapping.
        // address(0) is a special address in Ethereum that represents the absence of an address.
        // It's the default value for address types when they are not explicitly set.
        require(addressList[_name] == address(0), "Name already exist in the addressList");

        addressList[_name] = _address;
    }

    // Modifier: Ensure that name is present in the addressList
    modifier validName(string calldata _name) {
        require(addressList[_name] != address(0), "Name not present in the addressList");
        _;
    }

    // Internal function to get an address from the addressList 
    function getAddress(string calldata _name) internal view onlyOwner validName(_name) returns (address) {
        return addressList[_name];
    }

    // Remote an address from addressList
    function removeAddress(string calldata _name) external onlyOwner() validName(_name) {
        delete addressList[_name];
    }

    // Check balance of the contract
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Retrieve transaction details based on transaction ID
    function retrieveTransaction(bytes32 _txId) external view returns (address, address, uint256, uint256) {
        Transaction memory txDetails = transactionRecord[_txId];
        // Check whether transaction with this ID is present or not in the list.
        require(txDetails.sender != address(0), "Transaction not found"); 
        
        return (txDetails.sender, txDetails.recipient, txDetails.amount, txDetails.timestamp);
    }
}
