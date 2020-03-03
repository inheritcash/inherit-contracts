pragma solidity ^0.5.8;
import "../transfership/ERC721Handler.sol";

contract DeadOrAliveController is ERC721Handler {
  // This smart contract will control when to start draining all assets
  uint256 public lastInteraction;
  uint256 public unixDurationToHitButton;
  uint256 public unixDurationToOpenRemainingAssetsToAllBeneficiaries;
  constructor() public
    {
        lastInteraction = block.timestamp;
         // Default 1 year
        unixDurationToHitButton = uint256(31000000);
        // Default to 5 year
        unixDurationToOpenRemainingAssetsToAllBeneficiaries = uint256(155000000);
    }

  function hitTheDamnButton() public onlyOwner returns (uint256 timestamp)
  {
         lastInteraction = block.timestamp;
         return lastInteraction;
  }

  function assignUnixDurationToHitButton(uint256 newDuration) public onlyOwner returns (uint256 addedDuration) {
        unixDurationToHitButton = newDuration;
        return newDuration;
  }

  function assignUnixDurationToOpenRemainingAssetsToAllBeneficiaries(uint256 newDuration) public onlyOwner returns (uint256 addedDuration) {
        unixDurationToOpenRemainingAssetsToAllBeneficiaries = newDuration;
        return newDuration;
  }

  function overdueButton() public view returns (bool isOverdue) {
        if (block.timestamp > lastInteraction.add(unixDurationToHitButton)) {
            return true;
        } else {
            return false;
        }
  }

  function overdueBeneficiaryOpenRemainingAssets() public view returns (bool isOverdue) {
        if (block.timestamp > lastInteraction.add(unixDurationToHitButton).add(unixDurationToOpenRemainingAssetsToAllBeneficiaries)) {
            return true;
        } else {
            return false;
      }
    }
}
