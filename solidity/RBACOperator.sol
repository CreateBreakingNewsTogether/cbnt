pragma solidity ^0.4.24;
import "./RBAC.sol";
import "./Ownable.sol";

contract RBACOperator is Ownable, RBAC{

  /**
   * A constant role name for indicating operator.
   */
  string public constant ROLE_OPERATOR = "operator";

  /**
   * @dev the modifier to operate
   */
  modifier hasOperationPermission() {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }

  /**
   * @dev add a operator role to an address
   * @param _operator address
   */
  function addOperater(address _operator) public onlyOwner {
    addRole(_operator, ROLE_OPERATOR);
  }

  /**
   * @dev remove a operator role from an address
   * @param _operator address
   */
  function removeOperater(address _operator) public onlyOwner {
    removeRole(_operator, ROLE_OPERATOR);
  }
}
