pragma solidity ^0.4.24;

import "./PausableToken.sol";
import "./RBACMintableToken.sol";

/**
 * @dev cbnt token ERC20 contract
 * Based on references from OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
 */
contract Cbnt is RBACMintableToken, PausableToken {
  string public constant version = "1.1";
  string public constant name = "Create Breaking News Together";
  string public constant symbol = "CBNT";
  uint8 public constant decimals = 18;
  uint256 public constant MAX_AMOUNT = 10000000000000000000000000000;

  event Burn(address indexed burner, uint256 value);
  function mintToAddresses(address[] _addresses, uint256 _amount) public hasMintPermission canMint returns (bool){
    for (uint i = 0; i < _addresses.length; i++) {
      mint(_addresses[i],_amount);
    }
    return true;
  }
  function mintToAddressesAndAmounts(address[] _addresses, uint256[] _amounts) public hasMintPermission canMint returns (bool){
    require(_addresses.length == _amounts.length);
    for (uint i = 0; i < _addresses.length; i++) {
      mint(_addresses[i],_amounts[i]);
    }
    return true;
  }

  /**
   * @dev Overrides parent method to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require((_amount+totalSupply_) <= MAX_AMOUNT && _to != address(0));
    return super.mint(_to,_amount);
  }

  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }

}
