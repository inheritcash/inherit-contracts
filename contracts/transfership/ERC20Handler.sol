pragma solidity ^0.5.8;

import "../tokens/ERC20Interface.sol";
import "../safemath/SafeMath.sol";

contract ERC20Handler {

  using SafeMath for uint256;

  struct Transfer {
    address contractAddress;
    address to;
    uint amount;
    bool failed;
  }

  struct Erc20Token {
    uint256 index;
    uint256 totalWeiWithdrawn;
  }

  mapping(address => uint[]) public transactionIndexesToSender;

  address principleAccount;

  /**
  * List of all transfers successful or unsuccessful */
  Transfer[] public transactions;

  mapping(address => Erc20Token) public erc20ContractAddressToTokenInfo;
  address[] public erc20TokenContracts;

  event TransferSuccessful(address indexed from, address indexed to, uint256 amount);

  event TransferFailed(address indexed from, address indexed to, uint256 amount);

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == principleAccount;
  }
  function addNewERC20Token(address contractAddress) public onlyOwner returns (bool) {
    require(!checkIfErc20OnList(contractAddress));

     erc20ContractAddressToTokenInfo[contractAddress].index = erc20TokenContracts.push(contractAddress).sub(1);
     erc20ContractAddressToTokenInfo[contractAddress].totalWeiWithdrawn = 0;

    // Add approval for this token contract afterwards
    return true;
 }

  function removeERC20Token(address contractAddress) public onlyOwner returns (bool) {
    require(checkIfErc20OnList(contractAddress));

    uint256 rowToDelete = erc20ContractAddressToTokenInfo[contractAddress].index;
    address keyToMove = erc20TokenContracts[erc20TokenContracts.length-1];
    erc20TokenContracts[rowToDelete] = keyToMove;
    erc20ContractAddressToTokenInfo[keyToMove].index = rowToDelete;
    erc20TokenContracts.length--;
    delete(erc20ContractAddressToTokenInfo[contractAddress]);

    ERC20Interface thisErc20Token = ERC20Interface(contractAddress);
    thisErc20Token.approve(address(this), 0); // TODO ************ Maybe we can rethink this.

    return true;
 }

// TODO Decide if this logic should be moved away from this class...
  function transferTokensThatHaveBeenApprovedFromTheToAddress(address tokenContract, address to, uint256 amount) internal {
    require(amount > 0);

    address from = msg.sender;

    ERC20Interface thisErc20Token = ERC20Interface(tokenContract);

    uint256 transactionId = transactions.push(
    Transfer({
              contractAddress:  tokenContract,
              to: to,
              amount: amount,
              failed: true
    })
   );
    transactionIndexesToSender[from].push(transactionId - 1);

    if(amount > thisErc20Token.allowance(from, address(this))) {
    emit TransferFailed(from, to, amount);
    revert();
   }
    thisErc20Token.transferFrom(from, to, amount);

    transactions[transactionId - 1].failed = false;

    emit TransferSuccessful(from, to, amount);
   }

  function checkIfErc20OnList(address erc20Address) public view returns (bool isOnList) {
      if(erc20TokenContracts.length == 0) return false;
      return (erc20TokenContracts[erc20ContractAddressToTokenInfo[erc20Address].index] == erc20Address);
  }

  function getERC20ListLength() public view returns (uint256 count) {
    return erc20TokenContracts.length;
  }
}
