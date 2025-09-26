// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";


contract zerrowOracle {
    address public setter;
    address newsetter;
    //--------------------------pyth Used Paras--------------------------
    address public  pythAddr;
    mapping(address => bytes32) public TokenToPythId;
    //----------------------------modifier ----------------------------
    modifier onlySetter() {
        require(msg.sender == setter, 'SLC Vaults: Only Manager Use');
        _;
    }
    //------------------------------------ ----------------------------

    constructor() {
        setter = msg.sender;
    }

    function transferSetter(address _set) external onlySetter{
        newsetter = _set;
    }
    function acceptSetter(bool _TorF) external {
        require(msg.sender == newsetter, 'SLC Vaults: Permission FORBIDDEN');
        if(_TorF){
            setter = newsetter;
        }
        newsetter = address(0);
    }
    function setup( address _pythAddr ) external onlySetter{
        pythAddr = _pythAddr;
    }

    function TokenToPythIdSetup(address tokenAddress, bytes32 pythId) external onlySetter{
        TokenToPythId[tokenAddress] = pythId;
    }
    //-----------------------------------Special token handling----------------------------------------


    //-----------------------------------Pyth Used functions-------------------------------------------

    function getPythBasicPrice(bytes32 id) internal view returns (PythStructs.Price memory price){
        price = IPyth(pythAddr).getPriceUnsafe(id);
    }

    function pythPriceUpdate(bytes[] calldata updateData) public payable {
        uint fee = IPyth(pythAddr).getUpdateFee( updateData);
        IPyth(pythAddr).updatePriceFeeds{ value: fee }(updateData);
    }

    function getPythPrice(address token) public view returns (uint price){
        PythStructs.Price memory priceBasic;
        uint tempPriceExpo ;
        if(TokenToPythId[token] != bytes32(0)){
            priceBasic = getPythBasicPrice(TokenToPythId[token]);
            tempPriceExpo = uint(int256(18+priceBasic.expo));
            price = uint(int256(priceBasic.price)) * (10**tempPriceExpo);
        }else{
            price = 0;
        }
    }

    function getPrice(address token) external view returns (uint price){
        return getPythPrice(token);
    }

    //  Native token return
    function  nativeTokenReturn() external onlySetter {
        uint amount = address(this).balance;
        address payable receiver = payable(msg.sender);
        (bool success, ) = receiver.call{value:amount}("");
        require(success,"Zerrow Oracle: 0g Transfer Failed");
    }
    // ======================== contract base methods =====================
    fallback() external payable {}
    receive() external payable {}

}
