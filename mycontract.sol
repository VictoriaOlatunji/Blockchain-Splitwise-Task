// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SplitWise {
    struct IOU {
        address creditor;
        int32 amount;
        uint creditor_id;
        bool _valid;
    }
    struct Debtor {
        IOU [] IOUs; // list of IOU
        address debtor;
        uint id;
        bool _valid;
    }
    mapping (address => mapping(address => IOU)) record; // debtor and creditor map to IOU. better accessibility 
    mapping (address => Debtor) debtorMap; // faster access 
    Debtor[] recordArr; // debtors to array of creditors, return with less gas.
    
    function add_IOU(address _creditor, int32 _amount) public returns (bool res){ // negative IOU is to resolve the loop
        require(msg.sender != _creditor, "One cannot owes to themself.");
        // * ignore case that record minus amount < 0 => error
        if (debtorMap[msg.sender]._valid == false){ // new user; index recordArr by map address to id in debtorMap
            IOU memory _IOU = IOU({creditor: _creditor, amount: _amount, creditor_id: 0, _valid: true});
            Debtor storage debtor = debtorMap[msg.sender]; // initialized with variable outside of the function is required, so that append is possible
            record[msg.sender][_creditor] = _IOU;
            debtor.IOUs.push(_IOU); // add an IOU in a debtor's IOU list
            debtor.debtor = msg.sender;
            debtor.id = recordArr.length;
            debtor._valid = true;
            recordArr.push(debtor);
            debtorMap[msg.sender] = debtor;
            return true;
        }
        else if (record[msg.sender][_creditor]._valid == false) { // debtor's new creditor
            IOU memory _IOU = IOU({creditor: _creditor, amount: _amount, creditor_id: recordArr[debtorMap[msg.sender].id].IOUs.length, _valid: true});
            record[msg.sender][_creditor] = _IOU;
            recordArr[debtorMap[msg.sender].id].IOUs.push(_IOU);
            return true;
        }
        else{ // update IOU
            require(record[msg.sender][_creditor].amount + _amount >= 0, "tx results to negative IOU.");
            record[msg.sender][_creditor].amount += _amount;
            recordArr[debtorMap[msg.sender].id].IOUs[record[msg.sender][_creditor].creditor_id].amount += _amount; 
            if (record[msg.sender][_creditor].amount == 0){
                record[msg.sender][_creditor]._valid = false;
                recordArr[debtorMap[msg.sender].id].IOUs[record[msg.sender][_creditor].creditor_id]._valid = false;
            } else {
                record[msg.sender][_creditor]._valid = true;
                recordArr[debtorMap[msg.sender].id].IOUs[record[msg.sender][_creditor].creditor_id]._valid = true;
            }
            return true;
        }
        //return false;
    }

    function getrecord() public view returns(Debtor[] memory _recordArr){
        return recordArr;
    }

    function lookup(address debtor, address creditor) public view returns(int32 ret){
        return record[debtor][creditor].amount;
    }
}