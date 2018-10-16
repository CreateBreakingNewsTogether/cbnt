pragma solidity ^0.4.24;

import "./Crowdsale.sol";
import "./WhitelistedCrowdsale.sol";
import "./TimedCrowdsale.sol";

/**
 * @title CbntCrowdsale
 * @dev Crowdsale smart contract for CBNT token
 */
contract CbntCrowdsale is TimedCrowdsale, WhitelistedCrowdsale {
  using SafeMath for uint256;


  struct FutureTransaction{
    address beneficiary;
    uint256 num;
    uint32  times;
    uint256 lastTime;
  }
  FutureTransaction[] public futureTrans;
  uint256 public oweCbnt;

  uint256[] public rateSteps;
  uint256[] public rateStepsValue;
  uint32[] public regularTransTime;
  uint32 public transTimes;

  uint256 public minInvest;

 /**
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _openingTime, uint256 _closingTime, uint256 _rate, address _wallet, ERC20 _token) TimedCrowdsale(_openingTime,_closingTime) Crowdsale(_rate,_wallet, _token) public {
   // Crowdsale(uint256(1),_wallet, _token);
    //TimedCrowdsale(_openingTime,_closingTime);
  }

  /** external functions **/
  function triggerTransaction(uint256 beginIdx, uint256 endIdx) public returns (bool){
    uint32 regularTime = findRegularTime();
    require(regularTime > 0 && endIdx < futureTrans.length);

    bool bRemove = false;
    uint256 i = 0;
    for(i = beginIdx; i<=endIdx && i<futureTrans.length; ){
      bRemove = false;
      if(futureTrans[i].lastTime < regularTime){  // need to set the regularTime again when it comes late than the last regularTime
         uint256 transNum = futureTrans[i].num;
         address beneficiary = futureTrans[i].beneficiary;
         //update data

         futureTrans[i].lastTime = now;
         futureTrans[i].times = futureTrans[i].times - 1;
         require(futureTrans[i].times <= transTimes);

         // remove item if it is the last time transaction
         if(futureTrans[i].times ==0 ){
            bRemove = true;
            futureTrans[i].beneficiary = futureTrans[futureTrans.length -1].beneficiary;
            futureTrans[i].num = futureTrans[futureTrans.length -1].num;
            futureTrans[i].lastTime = futureTrans[futureTrans.length -1].lastTime;
            futureTrans[i].times = futureTrans[futureTrans.length -1].times;
            futureTrans.length = futureTrans.length.sub(1);
         }
            // transfer token
         oweCbnt = oweCbnt.sub(transNum);
         _deliverTokens(beneficiary, transNum);
      }

      if(!bRemove){
        i++;
      }
    }

    return true;

  }
  function transferBonus(address _beneficiary, uint256 _tokenAmount) public onlyOwner returns(bool){
    _deliverTokens(_beneficiary, _tokenAmount);
    return true;
  }

  // need to set this param before start business
  function setMinInvest(uint256 _minInvest) public onlyOwner returns (bool){
    minInvest = _minInvest;
    return true;
  }

  // need to set this param before start business
  function setTransTimes(uint32 _times) public onlyOwner returns (bool){
    transTimes = _times;
    return true;
  }

  function setRegularTransTime(uint32[] _times) public onlyOwner returns (bool){
    for (uint256 i = 0; i + 1 < _times.length; i++) {
        require(_times[i] < _times[i+1]);
    }

    regularTransTime = _times;
    return true;
  }

  // need to set this param before start business
  function setRateSteps(uint256[] _steps, uint256[] _stepsValue) public onlyOwner returns (bool){
    require(_steps.length == _stepsValue.length);
    for (uint256 i = 0; i + 1 < _steps.length; i++) {
        require(_steps[i] > _steps[i+1]);
    }

    rateSteps = _steps;
    rateStepsValue = _stepsValue;
    return true;
  }

  // need to check these params before start business
  function normalCheck() public view returns (bool){
    return (transTimes > 0 && regularTransTime.length > 0 && minInvest >0 && rateSteps.length >0);
  }

  function getFutureTransLength() public view returns(uint256) {
      return futureTrans.length;
  }
  function getFutureTransByIdx(uint256 _idx) public view returns(address,uint256, uint32, uint256) {
      return (futureTrans[_idx].beneficiary, futureTrans[_idx].num, futureTrans[_idx].times, futureTrans[_idx].lastTime);
  }
  function getFutureTransIdxByAddress(address _beneficiary) public view returns(uint256[]) {
      uint256 i = 0;
      uint256 num = 0;
      for(i=0; i<futureTrans.length; i++){
        if(futureTrans[i].beneficiary == _beneficiary){
            num++;
        }
      }
      uint256[] memory transList = new uint256[](num);

      uint256 idx = 0;
      for(i=0; i<futureTrans.length; i++){
        if(futureTrans[i].beneficiary == _beneficiary){
          transList[idx] = i;
          idx++;
        }
      }
      return transList;
  }

  /** internal functions **/
  /**
   * @dev Returns the rate of tokens per wei.
   * Note that, as price _increases_ with invest number, the rate _increases_.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens a buyer gets per wei
   */
  function getCurrentRate(uint256 _weiAmount) public view returns (uint256) {
    for (uint256 i = 0; i < rateSteps.length; i++) {
        if (_weiAmount >= rateSteps[i]) {
            return rateStepsValue[i];
        }
    }
    return 0;
  }

  /**
   * @dev Overrides parent method taking into account variable rate.
   * @param _weiAmount The value in wei to be converted into tokens
   * @return The number of tokens _weiAmount wei will send at present time
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 currentRate = getCurrentRate(_weiAmount);
    return currentRate.mul(_weiAmount).div(transTimes);
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(msg.value >= minInvest);
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    // update the future transactions for future using.
    FutureTransaction memory tran = FutureTransaction(_beneficiary, _tokenAmount, transTimes-1, now); // the trtanstimes always lagger than 0
    futureTrans.push(tran);

    //update owe cbnt
    oweCbnt = oweCbnt.add(_tokenAmount.mul(tran.times));
    super._processPurchase(_beneficiary, _tokenAmount);
  }

  function findRegularTime() internal view returns (uint32) {
    if(now < regularTransTime[0]){
      return 0;
    }

    uint256 i = 0;
    while(i<regularTransTime.length && now >= regularTransTime[i]){
      i++;
    }

    return regularTransTime[i -1];

  }

}
