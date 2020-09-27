pragma solidity >=0.4.7 <0.6.0;

import "./Database.sol";

contract Product {
  // Reference to its database contract.
  address public DATABASE_CONTRACT;
  // Reference to its product factory.
  address public PRODUCT_FACTORY;

  // This struct represents an action realized by a handler on the product.
  struct Action {
    // address of the individual or the organization who realizes the action.
    address handler;
    // description of the action.
    bytes32 description;

    // Longitude x10^10 where the Action is done.
    int lon;
    // Latitude x10^10 where the Action is done.
    int lat;

    // Instant of time when the Action is done.
    uint timestamp;
    // Block when the Action is done.
    uint blockNumber;
  }

  // if the Product is consumed the transaction can't be done.
  modifier notConsumed {
    if (isConsumed)
      throw;
    _;
  }

  // addresses of the products which were used to build this Product.
  address[] public parentProducts;
  // addresses of the products which are built by this Product.
  address[] public childProducts;

  // indicates if a product has been consumed or not.
  bool public isConsumed;

  // indicates the name of a product.
  bytes32 public name;

  // Additional information about the Product, generally as a JSON object
  bytes32 public additionalInformation;

  // all the actions which have been applied to the Product.
  Action[] public actions;

  function Product(bytes32 _name, bytes32 _additionalInformation, address[] _parentProducts, int _lon, int _lat, address _DATABASE_CONTRACT, address _PRODUCT_FACTORY) {
    name = _name;
    isConsumed = false;
    parentProducts = _parentProducts;
    additionalInformation = _additionalInformation;

    DATABASE_CONTRACT = _DATABASE_CONTRACT;
    PRODUCT_FACTORY = _PRODUCT_FACTORY;

    Action memory creation;
    creation.handler = msg.sender;
    creation.description = "Product creation";
    creation.lon = _lon;
    creation.lat = _lat;
    creation.timestamp = now;
    creation.blockNumber = block.number;

    actions.push(creation);

    Database database = Database(DATABASE_CONTRACT);
    database.storeProductReference(this);
  }

  function () {
    // If anyone wants to send Ether to this contract, the transaction gets rejected
    throw;
  }

  function addAction(bytes32 description, int lon, int lat, bytes32[] newProductsNames, bytes32[] newProductsAdditionalInformation, bool _consumed) notConsumed {
    if (newProductsNames.length != newProductsAdditionalInformation.length) throw;

    Action memory action;
    action.handler = msg.sender;
    action.description = description;
    action.lon = lon;
    action.lat = lat;
    action.timestamp = now;
    action.blockNumber = block.number;

    actions.push(action);

    ProductFactory productFactory = ProductFactory(PRODUCT_FACTORY);

    for (uint i = 0; i < newProductsNames.length; ++i) {
      address[] memory parentProducts = new address[](1);
      parentProducts[0] = this;
      productFactory.createProduct(newProductsNames[i], newProductsAdditionalInformation[i], parentProducts, lon, lat, DATABASE_CONTRACT);
    }

    isConsumed = _consumed;
  }

  function merge(address[] otherProducts, bytes32 newProductName, bytes32 newProductAdditionalInformation, int lon, int lat) notConsumed {
    ProductFactory productFactory = ProductFactory(PRODUCT_FACTORY);
    address newProduct = productFactory.createProduct(newProductName, newProductAdditionalInformation, otherProducts, lon, lat, DATABASE_CONTRACT);

    this.collaborateInMerge(newProduct, lon, lat);
    for (uint i = 0; i < otherProducts.length; ++i) {
      Product prod = Product(otherProducts[i]);
      prod.collaborateInMerge(newProduct, lon, lat);
    }
  }

  function collaborateInMerge(address newProductAddress, int lon, int lat) notConsumed {
    childProducts.push(newProductAddress);

    Action memory action;
    action.handler = this;
    action.description = "Collaborate in merge";
    action.lon = lon;
    action.lat = lat;
    action.timestamp = now;
    action.blockNumber = block.number;

    actions.push(action);

    this.consume();
  }

  function consume() notConsumed {
    isConsumed = true;
  }
}

contract ProductFactory {

    function ProductFactory() {}

    function () {
      // If anyone wants to send Ether to this contract, the transaction gets rejected
      throw;
    }

    function createProduct(bytes32 _name, bytes32 _additionalInformation, address[] _parentProducts, int _lon, int _lat, address DATABASE_CONTRACT) returns(address) {
      return new Product(_name, _additionalInformation, _parentProducts, _lon, _lat, DATABASE_CONTRACT, this);
    }
}
