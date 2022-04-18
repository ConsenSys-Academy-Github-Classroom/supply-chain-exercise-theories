// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner;// = msg.sender;

  // <skuCount>
  uint public skuCount;

  // <items mapping>
  //mapping (uint => Item) internal items;
  Item[] public items; 

  // <enum State: ForSale, Sold, Shipped, Received>
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint indexed sku);

  // <LogSold event: sku arg>
  event LogSold(uint indexed sku);

  // <LogShipped event: sku arg>
  event LogShipped(uint indexed sku);

  // <LogReceived event: sku arg>
  event LogReceived(uint indexed sku);

  // for compiler version 0.5.x
    function () external payable {
      revert();
    }

  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  // <modifier: isOwner
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }


  modifier isSeller(uint _sku) {
    Item memory _item = items[_sku];
    require(msg.sender == _item.seller);
    // assert (msg.sender == _item.seller);
    _;
  }

  modifier isBuyer(uint _sku) {
    Item memory _item = items[_sku];
    require(msg.sender == _item.buyer);
    _;
  }

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _sku) {
    Item storage item = items[_sku];
    // require(msg.value >= item.price);
    assert(msg.value >= item.price);
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    Item storage item = items[_sku];
    // uint _price = item.price;
    if (msg.value > item.price){
      // items[_sku].buyer.transfer(msg.value - _price);

      (bool success, ) = item.buyer.call.value(msg.value-item.price)("");
      
        // (bool success, bytes memory returnedData) = item.buyer.call{value: (msg.value - item.price) }("");
        // item.buyer.transfer(msg.value - item.price);
    }
    // uint amountToRefund = msg.value - _price;
    // if(amountToRefund > 0) {
      // items[_sku].buyer.transfer(amountToRefund);
    // }
    
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  // modifier forSale
  modifier forSale(uint sku) {
    Item memory _item = items[sku];
    require(_item.state == State.ForSale);
    require(_item.seller > address(0));
    _;

  }


  // modifier sold(uint _sku) 
  modifier sold(uint _sku) {
    Item memory _item = items[_sku];
    require(_item.state == State.Sold);
    require(_item.seller > address(0));
    require(_item.buyer > address(0));
    _;
  }
  // modifier shipped(uint _sku) 
  modifier shipped(uint _sku){
    Item memory _item = items[_sku];
    require(_item.state == State.Shipped);
    require(_item.seller > address(0));
    require(_item.buyer > address(0));
    _;
  }
  // modifier received(uint _sku) 
  modifier received(uint _sku){
    Item memory _item = items[_sku];
    require(_item.state == State.Received);
    require(_item.seller > address(0));
    require(_item.buyer > address(0));
    _;
  }

  constructor() public {
    // 1. Set the owner to the transaction sender
    owner =  msg.sender;
    // 2. Initialize the sku count to 0. Question, is this necessary?
    // skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    // 2. Increment the skuCount by one
    // 3. Emit the appropriate event
    // 4. return true
    
    items.push(Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    }));

    skuCount += 1;
    emit LogForSale(skuCount);
    return true;

    // hint:
    // items[skuCount] = Item({
    //  name: _name, 
    //  sku: skuCount, 
    //  price: _price, 
    //  state: State.ForSale, 
    //  seller: msg.sender, 
    //  buyer: address(0)
    //});
    //
    //skuCount = skuCount + 1;
    // emit LogForSale(skuCount);
    // return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!
  function buyItem(uint sku) public forSale(sku) paidEnough(sku) checkValue(sku) payable {

    Item storage item = items[sku];
    (bool success, ) = item.seller.call.value(item.price)("");
    // (bool success, bytes memory returnedData) = item.seller.call.value(item.price)("");
    // item.seller.transfer(msg.value);
    // (bool success, ) = item.seller.call{value: msg.value}("");
    if(success) {
      item.buyer = msg.sender;
      item.state = State.Sold;  

      emit LogSold(sku);
    }



  }

  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint sku) public sold(sku) isSeller(sku) {
    Item storage item = items[sku];
    item.state = State.Shipped;
    emit LogShipped(sku);

  }

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) public shipped(sku) isBuyer(sku) {
    Item storage _item = items[sku];
    _item.state = State.Received;
    emit LogReceived(sku);

  }

  // Uncomment the following code block. it is needed to run tests
 function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  { 
     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
   } 
}
