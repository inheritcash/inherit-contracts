pragma solidity ^0.5.8;

import "../../tokens/ERC20Interface.sol";
import "../../safemath/SafeMath.sol";

contract DummyERC20Token is ERC20Interface {
    using SafeMath for uint256;

    string public constant symbol = 'DUM';
    string public constant name = 'Dummytoken';
    uint8 public constant decimals = 18;

    string public constant version = "DUM 0.0";

    uint public totalSupply = 1 * 10**uint256(decimals);

    uint256 private constant MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        require(_from != address(this));
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
      * @dev this is a simple minting function so that we can test some tokens with balance
       */
    function mint(address account, uint256 value) public {
      require(account != address(0));
      totalSupply = totalSupply.add(value);
      balances[account] = balances[account].add(value);
      emit Transfer(address(0), account, value);
    }
}
