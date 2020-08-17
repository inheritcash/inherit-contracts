'use strict'

const BN = require("bn.js");
const increaseTime = require('./tools/increaseTime');

var web3Instance = require("web3");
var Web3 = new web3Instance('ws://localhost:8545');
const ERC20Token = artifacts.require('./DummyERC20Token.sol');
const ERC721Token = artifacts.require('./DummyERC721Full.sol');
const TokenDistribution = artifacts.require('./TokenDistribution.sol');
const ExecutorRegistry = artifacts.require("ExecutorRegistry.sol");

const should = require('chai')
  .use(require('chai-as-promised'))
  .use(require('chai-bn')(BN))
  .should();

contract('TokenDistribution', function ([owner, unknown, beneficiary1, beneficiary2, beneficiary3, treasury]) {

  let ZEROADDRESS = '0x0000000000000000000000000000000000000000';
  let erc20token;
  let erc721token;
  let tokenDistributor;
  let executorRegistry;
  let erc721Symbol = 'TST';
  let uniqueNameExecutorContract = 'FunContract';
  let fullETHShare = 10000;
  let oneThirdFullShare = 3333;
  let oneThirdShare = 333333;
  let fullERC20Share = 1000000;

  let registrationFee = 500000; // In szabo
  let gasCostToBeForwarded = 5000; // In szabo

  let registrationValue = registrationFee * Math.pow(10, 12); // 0.5 ETH
  let gasCostToBeForwardedValue = gasCostToBeForwarded * Math.pow(10, 12); // 0.005 ETH

  before(async function () {
    executorRegistry = await ExecutorRegistry.new(registrationFee, {from: treasury});
    erc20token = await ERC20Token.new();
    let mint = await erc20token.mint(
      owner, fullERC20Share,
      {from: owner}).should.be.fulfilled;
    erc721token = await ERC721Token.new(erc721Symbol, erc721Symbol);
    let nft = await erc721token.mint(
      owner, 2,
      {from: owner}).should.be.fulfilled;

    let nft2 = await erc721token.mint(
      owner, 100,
      {from: owner}).should.be.fulfilled;
    let nft3 = await erc721token.mint(
      owner, 101,
      {from: owner}).should.be.fulfilled;
    let nft4 = await erc721token.mint(
      owner, 102,
      {from: owner}).should.be.fulfilled;
  });

  it('should setup the distributor', async function () {
    const address721 = erc721token.address;
    const address20 = erc20token.address;
    const ownerBalance = await erc20token.balanceOf.call(owner);
    ownerBalance.should.be.bignumber.equal(new BN(fullERC20Share));

    let originalTreasurerBalance = await web3.eth.getBalance(treasury);
    let originalBeneficiary1Balance = await web3.eth.getBalance(beneficiary1);
    let originalBeneficiary2Balance = await web3.eth.getBalance(beneficiary2);

    tokenDistributor = await TokenDistribution.new([beneficiary1, beneficiary2],
      [Web3.utils.asciiToHex('test1'), Web3.utils.asciiToHex('test2')],
      [Web3.utils.asciiToHex('test@test.com'), Web3.utils.asciiToHex('test2@test.com')],
      [50, 50],
      new BN(31000000),
      new BN(155000000),
      [address20],
      [address721],
      uniqueNameExecutorContract,
      [beneficiary2, executorRegistry.address, beneficiary1, beneficiary2], // Beneficiary2 is default erc721, executor address, beneficiary 1 & 2 will receive gas money...
      {from: owner, value: (registrationValue + (2 * gasCostToBeForwardedValue))}).should.be.fulfilled; // 2 * gasforwarded for 2 beneficiaries receiving some gas money

    let newTreasurerBalanceAfterFee = await web3.eth.getBalance(treasury); // Earned 0.5 ETH

    let newBeneficiary1BalanceAfterFee = await web3.eth.getBalance(beneficiary1); // Earned 0.005 ETH
    let newBeneficiary2BalanceAfterFee = await web3.eth.getBalance(beneficiary2); // Earned 0.005 ETH

    // Ensure the treasury wallet got registration fee, and beneficiary wallets got some extra gas money
    assert.equal(Number(newBeneficiary1BalanceAfterFee.toString()), Number(originalBeneficiary1Balance.toString()) + gasCostToBeForwardedValue);
    assert.equal(Number(newBeneficiary2BalanceAfterFee.toString()), Number(originalBeneficiary2Balance.toString()) + gasCostToBeForwardedValue);
    assert.equal(Number(newTreasurerBalanceAfterFee.toString()), Number(originalTreasurerBalance.toString()) + registrationValue);

    let duration = await tokenDistributor.unixDurationToHitButton.call();
    duration.should.be.bignumber.equal(new BN(31000000));

    // Send more eth to the contract itself
    // Could also just be sent along with the original value to the contract
    await tokenDistributor.sendTransaction({from: owner, value: fullETHShare});

    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isFalse(overdueStatus);

    let erc20Supply = await erc20token.totalSupply.call();
    let approveERC20 = await erc20token.approve(
      tokenDistributor.address, erc20Supply,
      {from: owner}).should.be.fulfilled;

    let nftApproval = await erc721token.setApprovalForAll(
      tokenDistributor.address, true,
      {from: owner}).should.be.fulfilled;

    let executorContractQuery = await executorRegistry.getExecutorContract(owner);
    assert.equal(executorContractQuery, tokenDistributor.address);
  });

  it('random cannot to add compatible ERC20 Token', async function () {
    let updateToken = await tokenDistributor.addNewERC20Token(
      erc20token.address,
      {from: unknown}).should.be.rejectedWith('revert');
  });

  it('can remove and re add an ERC20 token', async function () {
    let updateToken = await tokenDistributor.removeERC20Token(
      erc20token.address,
      {from: owner}).should.be.fulfilled;

    let readdToken = await tokenDistributor.addNewERC20Token(
      erc20token.address,
      {from: owner}).should.be.fulfilled;
  });

  it('can remove and re add an ERC721 token', async function () {
    let updateToken = await tokenDistributor.removeERC721Token(
      erc721token.address,
      {from: owner}).should.be.fulfilled;

    let updateERC721Token = await tokenDistributor.addERC721TokenContractToList(
      erc721token.address,
      {from: owner}).should.be.fulfilled;
  });

  it('lets owner change duration to hit button', async function () {
    let newDuration = 60;
    let changeDuration = await tokenDistributor.assignUnixDurationToHitButton(
      newDuration,
      {from: owner}).should.be.fulfilled;
    var unixDurationToHitButton = await tokenDistributor.unixDurationToHitButton.call();
    unixDurationToHitButton.should.be.bignumber.equal(new BN(newDuration));
  });

  it('lets owner change duration to hit button for remaining assets', async function () {
    let newDuration = 60;
    let changeDuration = await tokenDistributor.assignUnixDurationToOpenRemainingAssetsToAllBeneficiaries(
      newDuration,
      {from: owner}).should.be.fulfilled;
    var unixDurationToHitButton = await tokenDistributor.unixDurationToOpenRemainingAssetsToAllBeneficiaries.call();
    unixDurationToHitButton.should.be.bignumber.equal(new BN(newDuration));
  });


  it('lets user assign specific beneficiaries to specific nfts', async function () {
    let specificNfts = await tokenDistributor.updateNFTWithSpecificBeneficiaries(
      erc721token.address,
      [100, 101, 102],
      [beneficiary1, beneficiary2, beneficiary3],
      {from: owner}).should.be.fulfilled;
  });

  it('owner can hit the damn button', async function () {
    var initialInteraction = await tokenDistributor.lastInteraction.call();
    let button = await tokenDistributor.hitTheDamnButton(
      {from: owner}).should.be.fulfilled;
  });

  it('is not overdue', async function () {
    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isFalse(overdueStatus);
  });

  it('becomes overdue', async function () {
    await increaseTime(65);
    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isTrue(overdueStatus);
  });

  it('is not overdue for remaining assets', async function () {
    var overdueStatus = await tokenDistributor.overdueBeneficiaryOpenRemainingAssets.call();
    assert.isFalse(overdueStatus);
  });

  it('owner can hit the button again afterwards', async function () {
    var initialInteraction = await tokenDistributor.lastInteraction.call();
    let button = await tokenDistributor.hitTheDamnButton(
      {from: owner}).should.be.fulfilled;
    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isFalse(overdueStatus);
  });

  it('lets owner add beneficiary', async function () {

    let addBeneficiary = await tokenDistributor.addBeneficiary(
      beneficiary3,
      Web3.utils.asciiToHex('friend3'),
      Web3.utils.asciiToHex('friend3@friend.com'),
      50,
      {from: owner}).should.be.fulfilled;

  });

  it('lets owner remove beneficiary', async function () {

    let removeBeneficiary = await tokenDistributor.removeBeneficiary(
      beneficiary3,
      {from: owner}).should.be.fulfilled;

  });

  it('lets owner re-add beneficiary and update nickname', async function () {

    let addBeneficiary = await tokenDistributor.addBeneficiary(
      beneficiary3,
      Web3.utils.asciiToHex('friend33'),
      Web3.utils.asciiToHex('friend33@friend.com'),
      50,
      {from: owner}).should.be.fulfilled;

    let beneficiaryStatus = await tokenDistributor.checkIfBeneficiary.call(beneficiary2);
    assert.isTrue(beneficiaryStatus);

    let updateBeneficiary = await tokenDistributor.updateBeneficiaryNickname(
      beneficiary2,
      Web3.utils.asciiToHex('friendlynickname'),
      {from: owner}).should.be.fulfilled;
  });

  it('lets owner update email', async function () {
    let updateBeneficiary = await tokenDistributor.updateBeneficiaryEmail(
      beneficiary2,
      Web3.utils.asciiToHex('friendforever@friend.com'),
      {from: owner}).should.be.fulfilled;
  });

  it('gets the count of beneficiaries', async function () {
    let count = await tokenDistributor.getBeneficiaryCount.call();
    count.should.be.bignumber.equal(new BN(3));
  });

  it('gets the beneficiary at correct index', async function () {
    let address = await tokenDistributor.getBeneficiaryAtIndex.call(1);
    address.should.be.equal(beneficiary2);
  });

  it('should get the sum of shares for all beneficiaries', async function () {
    let sumShares = await tokenDistributor.sumShares.call();
    sumShares.should.be.bignumber.equal(new BN(150));
  });

  it('should get the full eth share for a beneficiary after first timelock unix duration to hit button', async function () {
    await increaseTime(100);
    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isTrue(overdueStatus);
    let address = await tokenDistributor.calculateBeneficiariesCurrentEthAllowance.call(beneficiary1);
    address.should.be.bignumber.equal(new BN(oneThirdFullShare));
  });

  it('should get the full erc20 share for a beneficiary after first timelock unix duration to hit button', async function () {
    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isTrue(overdueStatus);

    let contracts = await tokenDistributor.erc20TokenContracts.call(0);
    contracts.should.be.equal(erc20token.address);

    let inheritancesBeneficiary1 = await tokenDistributor.getAllCurrentErc20Inheritances.call(beneficiary1);
    inheritancesBeneficiary1[0].should.be.bignumber.equal(new BN(oneThirdShare));

    await tokenDistributor.transferMeAllAssets(
      [], [],
      {from: beneficiary1}).should.be.fulfilled;

    const beneficiaryBalance = await erc20token.balanceOf.call(beneficiary1);
    beneficiaryBalance.should.be.bignumber.equal(new BN(oneThirdShare));

    // cant double dip, important check
    await tokenDistributor.transferMeAllAssets(
      [], [],
      {from: beneficiary1}).should.be.fulfilled;

    const beneficiaryBalance2 = await erc20token.balanceOf.call(beneficiary1);
    beneficiaryBalance2.should.be.bignumber.equal(new BN(oneThirdShare));
  });

  it('becomes overdue for remaining assets', async function () {
    await increaseTime(100);
    var overdueStatus = await tokenDistributor.overdueBeneficiaryOpenRemainingAssets.call();
    assert.isTrue(overdueStatus);
  });

  it('should get the full eth share for a beneficiary after second timelock unix duration to hit button', async function () {
    let address = await tokenDistributor.calculateBeneficiariesCurrentEthAllowance.call(beneficiary1);
    address.should.be.bignumber.equal(new BN(fullETHShare - oneThirdFullShare ));
  });

  it('should get the full erc20 share for a beneficiary after second timelock unix duration to hit button', async function () {
    let inheritancesBeneficiary1 = await tokenDistributor.getAllCurrentErc20Inheritances.call(beneficiary1);
    inheritancesBeneficiary1[0].should.be.bignumber.equal(new BN(fullERC20Share  - oneThirdShare));
  });


  it('should return the valid token ids for the beneficiary', async function () {

     const nftlistlength = await tokenDistributor.getNftListLength.call({from: beneficiary2});
    nftlistlength.should.be.bignumber.equal(new BN(1));
    const checkValidTokenIdForUser1 = await tokenDistributor.checkIfValidTokenIdForNFTUser.call(erc721token.address, 100, beneficiary1, {from:beneficiary1});
    checkValidTokenIdForUser1.should.be.equal(true);

    const checkValidTokenIdForUserMulti = await tokenDistributor.checkIfValidTokenIdsForMultipleNFTUser.call(
      [erc721token.address, erc721token.address, erc721token.address],
      [100, 101, 102],
      [beneficiary2, beneficiary2, beneficiary3],
      {from:beneficiary1});
    checkValidTokenIdForUserMulti[0].should.be.equal(false); // 100 owned by beneficiary 1, not 2.
    checkValidTokenIdForUserMulti[1].should.be.equal(true);
    checkValidTokenIdForUserMulti[2].should.be.equal(true);
  });

  it('should return the addresses that are beneficiary for a certain nft', async function () {

    const nftlistlength = await tokenDistributor.getNftListLength.call({from: beneficiary2});
    nftlistlength.should.be.bignumber.equal(new BN(1));

    const checkBeneficiaryForSpecificNftTokenIds = await tokenDistributor.getBeneficiaryAddressesForSpecificTokenIdsSingleNft.call(
      erc721token.address,
      [100, 101, 102, 999],
      {from:beneficiary1});
    checkBeneficiaryForSpecificNftTokenIds[0].should.be.equal(beneficiary1);
    checkBeneficiaryForSpecificNftTokenIds[1].should.be.equal(beneficiary2);
    checkBeneficiaryForSpecificNftTokenIds[2].should.be.equal(beneficiary3);
    checkBeneficiaryForSpecificNftTokenIds[3].should.be.equal('0x0000000000000000000000000000000000000000');
  });


  it('should transfer all assets to beneficiary', async function () {

    const beneficiaryInitialBalance = await erc20token.balanceOf.call(beneficiary2, {from: beneficiary2});
    beneficiaryInitialBalance.should.be.bignumber.equal(new BN(0));

    let tokenHolder721 =  await erc721token.ownerOf.call(2);
    tokenHolder721.should.be.equal(owner);

    await tokenDistributor.transferMeAllAssets(
      [erc721token.address, erc721token.address], [2, 101],
      {from: beneficiary2}).should.be.fulfilled;

    const beneficiaryBalance = await erc20token.balanceOf.call(beneficiary2);
    beneficiaryBalance.should.be.bignumber.equal(new BN(fullERC20Share - oneThirdShare));

    let tokenHolder721NewId101 =  await erc721token.ownerOf.call(101);
    tokenHolder721NewId101.should.be.equal(beneficiary2);


    let tokenHolder721NewId2 =  await erc721token.ownerOf.call(2);
    tokenHolder721NewId2.should.be.equal(beneficiary2);
  });

  it('should successfully use the utilities', async function () {
    await tokenDistributor.reclaimETH().should.be.fulfilled;
    await tokenDistributor.reclaimERC20(erc20token.address).should.be.fulfilled;
      await tokenDistributor.reclaimERC20(erc20token.address, {from: beneficiary2}).should.be.fulfilled;
      await tokenDistributor.selfDestructAndRemoveFromRegistry().should.be.fulfilled;
      let executorContractQuery = await executorRegistry.getExecutorContract(owner);
      assert.equal(await erc20token.balanceOf.call(tokenDistributor.address), 0);
      assert.equal(executorContractQuery, ZEROADDRESS);
  });
});

