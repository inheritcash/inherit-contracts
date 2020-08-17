pragma solidity ^0.5.8;
import "./BeneficiaryRoleController.sol";

contract SharesController is BeneficiaryRoleController {
  using SafeMath for uint256;
  uint256 totalWeiOfEthWithdrawn;
  uint256 totalMaximumWeiOfEthBalance;
  // The button will determine the mode - dead or alive - alive may mean that an allowance is available.
  // We have "percentage" values to divide up the allocation of what's available

  // At any given moment amount of wei that beneficiary can withdraw = ((total current balance + amount all withdrawn) / share %) - previous withdraw

  function calculateBeneficiariesCurrentEthAllowance(address beneficiary) public view returns (uint256 ethAllowance) {
    // Make sure user is a beneficiary
    require(checkIfBeneficiary(beneficiary), "Not a beneficiary");

    // Get the current balance of Eth
    uint256 currentBalance = address(this).balance;

    // Get how much Eth has already been withdrawn by this beneficiary
    uint256 alreadyWithdrawnByBeneficiary = userStructs[beneficiary].ethHasWithdrawn;

    // Get the maximum balance this contract has in case there is more funds added
    uint256 maxBalance = totalMaximumWeiOfEthBalance;

    // If the current balance is greater then the remaining tokens on the max balance, there was more tokens received at some point.
    // Increment our max balance in this case
    if(currentBalance > maxBalance.sub(totalWeiOfEthWithdrawn)){
      maxBalance = currentBalance.sub(totalWeiOfEthWithdrawn);
    }

    // Calculate the share of ETH this user can receive based on MAX Eth available balance
    uint256 ethShareCalc = maxBalance.mul(userStructs[beneficiary].share);
    uint256 ethShare= ethShareCalc.div(sumShares());

    // Double dipping, only allow this if it seems there are more tokens during timelock
    uint256 currentInheritance = 0;
    if (ethShare > alreadyWithdrawnByBeneficiary) {
      currentInheritance = ethShare.sub(alreadyWithdrawnByBeneficiary);
    }

    // If the resulting amount is greater than the actual balance, just give actual balance
    if(currentBalance < currentInheritance) {
      currentInheritance = currentBalance;
    }

    // If button is not overdue, nothing available yet.
    if(!overdueButton()){
      currentInheritance = 0;
    }

    // If it reaches the second time lock, let any beneficiary take out what's left
    if(overdueBeneficiaryOpenRemainingAssets()){
      currentInheritance = currentBalance;
    }

    return currentInheritance;
  }

  function calculateBeneficiariesCurrentErc20Inheritance(address erc20Contract, address beneficiary) public view returns (uint256 erc20Balance) {
    // Make sure user is a beneficiary
    require(checkIfBeneficiary(beneficiary), "Not a beneficiary");

    // Set up the erc20 interface
    ERC20Interface erc20 = ERC20Interface(erc20Contract);

    // Get the remaining allowance for the contract and the current erc20 balance
    uint256 remainingAllowance = erc20.allowance(principleAccount, address(this));
    uint256 currentBalance = erc20.balanceOf(principleAccount);

    // Get the total that has already been withdrawn by all users and by this beneficiary
    uint256 alreadyWithdrawnTotal = erc20ContractAddressToTokenInfo[erc20Contract].totalWeiWithdrawn;
    uint256 alreadyWithdrawnByBeneficiary = userStructs[beneficiary].erc20TokenBalanceHasWithdrawn[erc20Contract];

    // Get the maximum balance this contract has in case there is more funds added
    uint256 maxBalance = erc20ContractAddressToTokenInfo[erc20Contract].totalWeiBalanceMax;

    // Check that the current allowance is sufficient to distribute the current balance, if not set currentBalance to remaining allowance
    if(remainingAllowance < currentBalance) {
      currentBalance = remainingAllowance;
    }

    // If the current balance is greater then the remaining tokens on the max balance, there was more tokens received at some point.
    // Increment our max balance in this case
    if(currentBalance > maxBalance.sub(alreadyWithdrawnTotal)){
      maxBalance = currentBalance.sub(alreadyWithdrawnTotal);
    }

    uint256 originalShareForBeneficiaryCalc = maxBalance.mul(userStructs[beneficiary].share);
    uint256 currentInheritance = originalShareForBeneficiaryCalc.div(sumShares());

    // Double dipping, only allow this if it seems there are more tokens during timelock
    if (currentInheritance <= alreadyWithdrawnByBeneficiary) {
      currentInheritance = 0;
    } else {
      currentInheritance = currentInheritance.sub(alreadyWithdrawnByBeneficiary);
    }

    // If the resulting amount is greater than the actual balance, just give actual balance
    if(currentBalance < currentInheritance) {
      currentInheritance = currentBalance;
    }

    // If the allowance is less than the current inheritance to withdraw by this point, adjust again.
    if(remainingAllowance < currentInheritance) {
      currentInheritance = remainingAllowance;
    }

    // If button is not overdue, nothing available yet.
    if(!overdueButton()){
      currentInheritance = 0;
    }

    // If it reaches the second time lock, let any beneficiary take out what's left
    if(overdueBeneficiaryOpenRemainingAssets()){
      currentInheritance = currentBalance;
    }
    return currentInheritance;
  }

  function getAllCurrentErc20Inheritances(address beneficiary) public view returns (uint256[] memory erc20WithdrawalBalances) {
      uint256[] memory erc20ContractWithdrawalBalance = new uint256[](erc20TokenContracts.length);
      for (uint i=0; i < erc20TokenContracts.length; i++) {
        erc20ContractWithdrawalBalance[i]= calculateBeneficiariesCurrentErc20Inheritance(erc20TokenContracts[i], beneficiary);
      }
      return erc20ContractWithdrawalBalance;
  }
}
