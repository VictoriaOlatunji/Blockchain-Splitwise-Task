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
    mapping (address => mapping(address => IOU)) register; // to map debtor and creditor map IOU for better accessibility 
    mapping (address => Debtor) debtorMap; // map debtor to IOU for faster accessibility 
    Debtor[] registerArr; // debtors to array of creditors, return with less gas.
    
    function add_IOU(address _creditor, int32 _amount) public returns (bool res){ // negative IOU is to resolve the loop
        require(msg.sender != _creditor, "One cannot owes to themself.");
        // * ignore case that register minus amount < 0 => error
        if (debtorMap[msg.sender]._valid == false){ // new user; 
            IOU memory _IOU = IOU({creditor: _creditor, amount: _amount, creditor_id: 0, _valid: true});
            Debtor storage debtor = debtorMap[msg.sender]; 
            register[msg.sender][_creditor] = _IOU;
            debtor.IOUs.push(_IOU); // add an IOU in a debtor's IOU list
            debtor.debtor = msg.sender;
            debtor.id = registerArr.length;
            debtor._valid = true;
            registerArr.push(debtor);
            debtorMap[msg.sender] = debtor;
            return true;
        }
        else if (register[msg.sender][_creditor]._valid == false) { // debtor's new creditor
            IOU memory _IOU = IOU({creditor: _creditor, amount: _amount, creditor_id: registerArr[debtorMap[msg.sender].id].IOUs.length, _valid: true});
            register[msg.sender][_creditor] = _IOU;
            registerArr[debtorMap[msg.sender].id].IOUs.push(_IOU);
            return true;
        }
        else{ // update IOU
            require(register[msg.sender][_creditor].amount + _amount >= 0, "tx results to negative IOU.");
            register[msg.sender][_creditor].amount += _amount;
            registerArr[debtorMap[msg.sender].id].IOUs[register[msg.sender][_creditor].creditor_id].amount += _amount; 
            if (register[msg.sender][_creditor].amount == 0){
                register[msg.sender][_creditor]._valid = false;
                registerArr[debtorMap[msg.sender].id].IOUs[register[msg.sender][_creditor].creditor_id]._valid = false;
            } else {
                register[msg.sender][_creditor]._valid = true;
                registerArr[debtorMap[msg.sender].id].IOUs[register[msg.sender][_creditor].creditor_id]._valid = true;
            }
            return true;
        }
        return false;
    }

    //function to getregister
    function getregister() public view returns(Debtor[] memory _registerArr){
        return registerArr;
    }

     //function lookup to know the amount the debtor owes the creditor
    function lookup(address debtor, address creditor) public view returns(int32 ret){
        return register[debtor][creditor].amount;
    }
}