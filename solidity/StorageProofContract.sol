pragma solidity ^0.4.24;
import "./RBAC.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./RBACOperator.sol";

contract StorageProofContract is RBACOperator{
  using SafeMath for uint256;

  struct Writing{
    string user;
    uint256 time;
  }

  mapping (bytes32 => Writing) writings;     /* map of writing hash to writing data */
  bytes32[] public hashes;          /* the writing hash list*/
  mapping (string => bytes32[]) userWritings;     /* map of user to writing hashes */

  /**
   * Event for addWriting logging
   * @param user the author
   * @param hash the hash of the writing
   * @param timestamp the timestamp of execution
   */
  event AddWriting(
    string indexed user,
    bytes32 hash,
    uint256 timestamp
  );

  /*
  * @dev Store writing information
  * @param _hash The article hash
  * @param _user The author id
  */
  function addWriting(bytes32 _hash, string _user) public hasOperationPermission{
    require(_hash != 0 && writings[_hash].time == 0 && bytes(_user).length  > 0);
      uint256 timestamp = now;
      Writing memory writing = Writing(_user, timestamp);
      writings[_hash] = writing;
      hashes.push(_hash);
      userWritings[_user].push(_hash);
      emit AddWriting(_user, _hash, timestamp);
  }

  /*
  * @dev get writing
  * @param _hash writing hash
  */
  function getWriting(bytes32 _hash) public view returns(bytes32 hashCode,string user,uint256 time){
    require(_hash.length != 0);
    Writing storage writing = writings[_hash];
    return (_hash,writing.user,writing.time);
  }

  /*
  * @dev get writing hashes of a user
  * @param _user writing hash
  */
  function getHashesByUser(string _user) public view returns(bytes32[] hashList){
    require(bytes(_user).length  > 0);
    return userWritings[_user];
  }

  /*
  * @dev get writing count
  */
  function getWritingCount() public view returns(uint256){
      return hashes.length;
  }


  function getIds(uint256 beginIdx, uint256 endIdx) public view returns(bytes32[]){
    require(hashes.length > 0 && beginIdx <= endIdx);

    uint256 finalIdx = endIdx > hashes.length -1 ? hashes.length - 1: endIdx;
    bytes32[] memory idxHashes = new bytes32[](finalIdx-beginIdx+1);

    uint256 idx = 0;
    for(uint256 i = beginIdx; i <= finalIdx; i++){
      idxHashes[idx] = hashes[i];
      idx++;
    }
    return idxHashes;
  }

}
