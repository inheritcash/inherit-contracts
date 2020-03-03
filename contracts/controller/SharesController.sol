pragma solidity ^0.5.8;
import "./BeneficiaryRoleController.sol";

contract SharesController is BeneficiaryRoleController {
  using SafeMath for uint256;
  uint256 totalWeiOfEthWithdrawn;
  // The button will determine the mode - dead or alive - alive may mean that an allowance is available.
  // We have "percentage" values to divide up the allocation of what's available

  // At any given moment amount of wei that beneficiary can withdraw = ((total current balance + amount all withdrawn) / share %) - previous withdraw

  function calculateBeneficiariesCurrentEthAllowance(address beneficiary) public view returns (uint256 ethAllowance) {
    require(checkIfBeneficiary(beneficiary));
    uint256 currentBalance = address(this).balance;
    uint256 alreadyWithdrawnByBeneficiary = userStructs[beneficiary].ethHasWithdrawn;
    uint256 originalBalance = currentBalance.add(totalWeiOfEthWithdrawn);
    uint256 ethShareCalc = originalBalance.mul(userStructs[beneficiary].share);
    uint256 ethShare= ethShareCalc.div(sumShares());
    uint256 currentInheritance = ethShare.sub(alreadyWithdrawnByBeneficiary);

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
    require(checkIfBeneficiary(beneficiary));
    ERC20Interface erc20 = ERC20Interface(erc20Contract);
    uint256 remainingAllowance = erc20.allowance(principleAccount, address(this));
    uint256 currentBalance = erc20.balanceOf(principleAccount);
    uint256 alreadyWithdrawnTotal = erc20ContractAddressToTokenInfo[erc20Contract].totalWeiWithdrawn;
    uint256 alreadyWithdrawnByBeneficiary = userStructs[beneficiary].erc20TokenBalanceHasWithdrawn[beneficiary];
    // Check that the current allowance is sufficient to distribute the current balance, if not set currentBalance to remaining allowance
    if(remainingAllowance < currentBalance) {
      currentBalance = remainingAllowance;
    }

    uint256 originalBalance = currentBalance.add(alreadyWithdrawnTotal);
    // Wei bug
    uint256 originalShareForBeneficiaryCalc = originalBalance.mul(userStructs[beneficiary].share);
    uint256 originalShareForBeneficiary = originalShareForBeneficiaryCalc.div(sumShares());
    uint256 currentInheritance = originalShareForBeneficiary.sub(alreadyWithdrawnByBeneficiary);
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

  function getAllCurrentErc20Inheritances(address beneficiary) public view returns (uint256[] memory erc20Balances) {
      uint256[] memory erc20ContractBalances = new uint256[](erc20TokenContracts.length);
      for (uint i=0; i < erc20TokenContracts.length; i++) {
        erc20ContractBalances[i]= calculateBeneficiariesCurrentErc20Inheritance(erc20TokenContracts[i], beneficiary);
      }
      return  erc20ContractBalances;
  }
}
