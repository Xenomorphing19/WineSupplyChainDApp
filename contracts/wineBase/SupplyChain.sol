// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../wineAccessControl/ConsumerRole.sol";
import "../wineAccessControl/DistributorRole.sol";
import "../wineAccessControl/RetailerRole.sol";
import "../wineAccessControl/VigneronRole.sol";
import "../wineCore/Ownable.sol";
// Define a contract 'Supplychain'

contract SupplyChain is Ownable, ConsumerRole, DistributorRole, RetailerRole, VigneronRole{

  // *** TERMINOLOGY ***
  // - Viticulture = grape growing and cultivating process
  // - Vinification = Winemaking process
  // - Elevage = Barrel ageing process
  // - Vigneron = a person who cultivates grapes for winemaking
  // - Vineyard = plantation of grape-bearing vines for winemaking 

  address payable contractOwner;

  //Universal Product Code (UPC)
  uint  upc;

  // Stock Keeping Unit (SKU)
  uint  sku;

  enum State 
  { 
    Viticultured, // 0
    Vinified,     // 1
    Elevaged,     // 2
    Packed,       // 3
    ForSale,      // 4
    Sold,         // 5
    Shipped,      // 6
    Received,     // 7
    Purchased     // 8
    }

  State constant defaultState = State.Viticultured;

  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the vigneron, goes on the package, can be verified by the Consumer
    address ownerID;  // address of the current owner as the product moves through 9 stages in the supply chain 
    address originVigneronID; 
    string  originVineyardName; 
    string  originVineyardInformation;
    string  originVineyardLatitude; 
    string  originVineyardLongitude; 
    uint    productID;  // Product ID = upc + sku
    uint256 productAge; // Age of the wine 
    string  productNotes; 
    uint    productPrice; 
    State   itemState; 
    address distributorID;  
    address retailerID; 
    address consumerID; 
    bool    initialised;
  }

  // UPC => Item
  mapping (uint => Item) items;

  
  event Viticultured(uint upc); // * Viticulture = grape growing and cultivating process
  event Vinified(uint upc); // * Vinification = Winemaking process
  event Elevaged(uint upc, uint age); // * Elevage = Barrel Ageing process
  event Packed(uint upc);
  event ForSale(uint upc);
  event Sold(uint upc);
  event Shipped(uint upc);
  event Received(uint upc);
  event Purchased(uint upc);

  
  constructor() payable {
    contractOwner = payable(msg.sender);
    sku = 1;
    upc = 1;
  }








  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

 
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }
  
  
  modifier checkValue(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    address consumer = items[_upc].consumerID;
    payable(consumer).transfer(amountToReturn);
  }

  modifier viticultured(uint _upc) {
    require(items[_upc].itemState == State.Viticultured, "The item state is not 'Harvested' ");
    _;
  }

  modifier vinified(uint _upc) {
    require(items[_upc].itemState == State.Vinified, "The item state is not 'Processed' ");
    _;
  }

  modifier elevaged(uint _upc) {
    require(items[_upc].itemState == State.Elevaged, "The item state is not 'Processed' ");
    _;
  }
  
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed, "The item state is not 'Packed' ");
    _;
  }

  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale, "The item state is not 'ForSale' ");
    _;
  }

  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold, "The item state is not 'Sold' ");
    _;
  }
  
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped, "The item state is not 'Shipped' ");
    _;
  }

  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received, "The item state is not 'Received' ");
    _;
  }

  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased, "The item state is not 'Purchased' ");
    _;
  }

  




  
  function kill() public {
    if (msg.sender == contractOwner) {
      selfdestruct(contractOwner);
    }
  }








  
  ///// **** SETTER/STAGE functions ****

  function viticultureItem(uint _upc, 
                       address _originVigneronID, 
                       string memory _originVineyardName, 
                       string memory _originVineyardInformation, 
                       string  memory _originVineyardLatitude, 
                       string  memory _originVineyardLongitude, 
                       string  memory _productNotes) 
  public onlyVigneron {
    require(items[_upc].initialised == false, "This upc is already in use");

    uint256 _productID = sku + _upc;

    items[_upc]= Item({
      sku: sku, 
      upc: _upc,
      ownerID: _originVigneronID,
      originVigneronID: _originVigneronID,
      originVineyardName: _originVineyardName,
      originVineyardInformation: _originVineyardInformation,  
      originVineyardLatitude: _originVineyardLatitude,
      originVineyardLongitude: _originVineyardLongitude,
      productID: _productID,
      productAge: 0, 
      productNotes: _productNotes,
      productPrice: 0,
      itemState: State.Viticultured,
      distributorID: address(0),  
      retailerID: address(0),
      consumerID: address(0),
      initialised: true
    });
    
    sku = sku + 1;

    emit Viticultured(_upc);
  }

  
  function vinifyItem(uint _upc) public onlyVigneron viticultured(_upc) verifyCaller(msg.sender){
    items[_upc].itemState = State.Vinified;
    emit Vinified(_upc);
  }


  function elevageItem(uint _upc, uint256 _age) public onlyVigneron vinified(_upc) verifyCaller(msg.sender){
    items[_upc].itemState = State.Elevaged;
    items[_upc].productAge = _age;
   
    emit Elevaged(_upc, _age);
  }

  
  function packItem(uint _upc) public onlyVigneron elevaged(_upc) verifyCaller(msg.sender){
    items[_upc].itemState = State.Packed;
 
    emit Packed(_upc);
  }

  
  function sellItem(uint _upc, uint _price) public onlyVigneron packed(_upc) verifyCaller(msg.sender){
    items[_upc].itemState = State.ForSale;
    items[_upc].productPrice = _price;
    
    emit ForSale(_upc);
  }

  
  function buyItem(uint _upc) public payable onlyRetailer forSale(_upc) paidEnough(items[_upc].productPrice) checkValue(_upc) {
    Item storage product = items[_upc];
    product.ownerID = msg.sender;
    product.retailerID = msg.sender;
    product.itemState = State.Sold;

    address vigneron = product.originVigneronID;
    uint256 amount = product.productPrice;

    (bool success, ) = payable(vigneron).call{value: amount}("");
    require(success, "Transfer failed");
    
    emit Sold(_upc);
  }

  
  function shipItem(uint _upc) public onlyDistributor sold(_upc) verifyCaller(msg.sender){
    items[_upc].itemState = State.Shipped;

    emit Shipped(_upc);
  }

  
  function receiveItem(uint _upc) public onlyRetailer shipped(_upc) {
    Item storage product = items[_upc];
    product.ownerID = msg.sender;
    product.retailerID = msg.sender;
    product.itemState = State.Received;
    
    emit Received(_upc);
  }


  function purchaseItem(uint _upc) public payable onlyConsumer received(_upc) paidEnough(items[_upc].productPrice) checkValue(_upc){
    Item storage product = items[_upc];
    product.ownerID = msg.sender;
    product.consumerID = msg.sender;
    product.itemState = State.Purchased;
    uint amount = product.productPrice;
    address retailer = product.retailerID;

    (bool success, ) = payable(retailer).call{value: amount}("");
    require(success, "Transfer failed");

    emit Purchased(_upc);
  }











  
  //**** GETTER Functions **** 

  function getProductPrice(uint256 _upc) public view returns(uint256 price){
    return items[_upc].productPrice;
  }

  function fetchItemBufferOne(uint _upc) public view returns 
  ( uint    itemSKU,
    uint    itemUPC,
    address ownerID,
    address originVigneronID,
    string  memory originVineyardName,
    string  memory originVineyardInformation,
    string  memory originVineyardLatitude,
    string  memory originVineyardLongitude,
    bool    initialised ) 
  {

  itemSKU = items[_upc].sku;
  itemUPC = _upc;
  ownerID = items[_upc].ownerID;
  originVigneronID = items[_upc].originVigneronID;
  originVineyardName = items[_upc].originVineyardName;
  originVineyardInformation = items[_upc].originVineyardInformation;
  originVineyardLatitude = items[_upc].originVineyardLatitude;
  originVineyardLongitude = items[_upc].originVineyardLongitude;
  initialised = items[_upc].initialised; 

    
  return ( itemSKU,
           itemUPC,
           ownerID,
           originVigneronID,
           originVineyardName,
           originVineyardInformation,
           originVineyardLatitude,
           originVineyardLongitude, 
           initialised);
  }


  function fetchItemBufferTwo(uint _upc) public view returns 
  ( uint    itemSKU,
    uint    itemUPC,
    uint    productID,
    uint    productAge,
    string  memory productNotes,
    uint    productPrice,
    uint    itemState,
    address distributorID,
    address retailerID,
    address consumerID ) 
  {

  itemSKU = items[_upc].sku;
  itemUPC = _upc;
  productID = items[_upc].productID;
  productAge = items[_upc].productAge;
  productNotes = items[_upc].productNotes;
  productPrice = items[_upc].productPrice;
  itemState = uint256(items[_upc].itemState);
  distributorID = items[_upc].distributorID;
  retailerID = items[_upc].retailerID;
  consumerID = items[_upc].consumerID;
    
  return 
  ( itemSKU,
    itemUPC,
    productID,
    productAge,
    productNotes,
    productPrice,
    itemState,
    distributorID,
    retailerID,
    consumerID );
  }

}
