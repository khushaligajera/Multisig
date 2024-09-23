// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.00;


contract MultiSig {
    struct TransactionInfo {
        address to;
        uint256 value;
        uint256 numOfConfirmation;
        bool isExecuted;
    }
    mapping(address => bool) isOwner;
    TransactionInfo[] public transactions;
    uint256 public numOfConfirmationRequired;
    address[] public owners;
    uint256 public countOfConfirmation;


    modifier onlyOwner(address sender) {
        require(isOwner[sender], "only owner");
        _;
    }


    modifier txtExist(uint256 index) {
        require(index <= numOfConfirmationRequired, "transaction not exist");
        _;
    }
    modifier isExecuted(uint256 index) {
        require(!transactions[index].isExecuted, "is already executed");
        _;
    }


    constructor(address[] memory owner, uint256 _numOfConfirmationRequired) {
        for (uint256 i = 0; i < owner.length; i++) {
            require(owner[i] != address(0), "address cannot be zero");
            require(!isOwner[owner[i]], "is already owner");
            isOwner[owner[i]] = true;
            owners.push(owner[i]);
            if (
                _numOfConfirmationRequired >= 2 &&
                _numOfConfirmationRequired <= owner.length
            ) {
                numOfConfirmationRequired = _numOfConfirmationRequired;
            }
        }
    }


    function submitTransaction(address _to) public payable {
        require(_to != address(0), "address cannot be zero");
        require(msg.value != 0, "send ETHER please");
        transactions.push(
            TransactionInfo({
                to: _to,
                value: msg.value,
                numOfConfirmation: 0,
                isExecuted: false
            })
        );
    }


    function confirmTransaction(uint256 transactionIndex)
        public
        txtExist(transactionIndex)
        isExecuted(transactionIndex)
        onlyOwner(msg.sender)
    {
        countOfConfirmation = transactions[transactionIndex]
            .numOfConfirmation += 1;
        transactions[transactionIndex].isExecuted = false;
        if (countOfConfirmation == numOfConfirmationRequired) {
            executeTransaction(transactionIndex);
        }
    }


    function executeTransaction(uint256 _transactionIndex)
        public
        payable
        txtExist(_transactionIndex)
        onlyOwner(msg.sender)
        isExecuted(_transactionIndex)
    {
        require(
            countOfConfirmation == numOfConfirmationRequired,
            "not confirmed by owner"
        );
        (bool success, ) = transactions[_transactionIndex].to.call{
            value: transactions[_transactionIndex].value
        }("");
        require(success, "tx failed");
        transactions[_transactionIndex].isExecuted = true;
    }
}

