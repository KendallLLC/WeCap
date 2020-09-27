pragma solidity >=0.4.7 <0.6.0;

import "./owned.sol";

contract Database is owned {
  //addresses of the Products referenced in this database
  address[] public products;

  //struct which represents a Handler for the products stored in the database.
  struct Handler {
    //indicates the name of a Handler.
    string _name;
    //Additional information about the Handler, generally as a JSON object
    string _additionalInformation;
  }

  //Relates an address with a Handler record.
  mapping(address => Handler) public addressToHandler;

  function Database() {}

  function () {
    // If anyone wants to send Ether to this contract, the transaction gets rejected
    throw;
  }

  function addHandler(address _address, string _name, string _additionalInformation) onlyOwner {
    Handler memory handler;
    handler._name = _name;
    handler._additionalInformation = _additionalInformation;

    addressToHandler[_address] = handler;
  }

  function storeProductReference(address productAddress) {
    products.push(productAddress);
  }

}
