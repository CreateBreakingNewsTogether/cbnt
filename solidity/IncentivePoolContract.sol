pragma solidity ^0.4.24;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./RBACOperator.sol";

contract IncentivePoolContract is Ownable, RBACOperator{
  using SafeMath for uint256;
  uint256 public openingTime;


  /**
   * @dev Overridden seOpeningTimed, takes pool opening  times.
   * @param _newOpeningTime opening time
   */
  function setOpeningTime(uint32 _newOpeningTime) public hasOperationPermission {
     require(_newOpeningTime > 0);
     openingTime = _newOpeningTime;
  }


  /*
   * @dev get the incentive number
   * @return yearSum The total amount of tokens released in the current year
   * @return daySum The total number of tokens released on the day
   * @return currentYear Current year number
   */
  function getIncentiveNum() public view returns(uint256 yearSum, uint256 daySum, uint256 currentYear) {
    require(openingTime > 0 && openingTime < now);
    (yearSum, daySum, currentYear) = getIncentiveNumByTime(now);
  }



  /*
   * @dev get the incentive number
   * @param _time The time to get incentives for
   * @return yearSum The total amount of tokens released in the current year
   * @return daySum The total number of tokens released on the day
   * @return currentYear Current year number
   */
  function getIncentiveNumByTime(uint256 _time) public view returns(uint256 yearSum, uint256 daySum, uint256 currentYear) {
    require(openingTime > 0 && _time > openingTime);
    uint256 timeSpend = _time - openingTime;
    uint256 tempYear = timeSpend / 31536000;
    if (tempYear == 0) {
      yearSum = 2400000000000000000000000000;
      daySum = 6575342000000000000000000;
      currentYear = 1;
    } else if (tempYear == 1) {
      yearSum = 1080000000000000000000000000;
      daySum = 2958904000000000000000000;
      currentYear = 2;
    } else if (tempYear == 2) {
      yearSum = 504000000000000000000000000;
      daySum = 1380821000000000000000000;
      currentYear = 3;
    } else {
      uint256 year = tempYear - 3;
      uint256 d = 9 ** year;
      uint256 e = uint256(201600000000000000000000000).mul(d);
      uint256 f = 10 ** year;
      uint256 y2 = e.div(f);

      yearSum = y2;
      daySum = y2 / 365;
      currentYear = tempYear+1;
    }
  }
}
