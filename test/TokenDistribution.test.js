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

contract('TokenDistribution', function ([owner, unknown, beneficiary1, beneficiary2, beneficiary3]) {

  let erc20token;
  let erc721token;
  let tokenDistributor;
  let erc721Symbol = 'TST';
  let uniqueNameExecutorContract = 'FunContract';
  let fullETHShare = 10000;
  let fullERC20Share = 1000000;

  before(async function () {
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
    let executorRegistry = await ExecutorRegistry.new();
    const address721 = erc721token.address;
    const address20 = erc20token.address;
    const ownerBalance = await erc20token.balanceOf.call(owner);
    ownerBalance.should.be.bignumber.equal(new BN(fullERC20Share));
    tokenDistributor = await TokenDistribution.new([beneficiary1, beneficiary2],
      [Web3.utils.asciiToHex('test1'), Web3.utils.asciiToHex('test2')],
      [Web3.utils.asciiToHex('test@test.com'), Web3.utils.asciiToHex('test2@test.com')],
      [50, 50],
      new BN(31000000),
      new BN(155000000),
      [address20],
      [address721],
      uniqueNameExecutorContract,
      [beneficiary2, executorRegistry.address],
      {from: owner, value: fullETHShare}).should.be.fulfilled;
    let duration = await tokenDistributor.unixDurationToHitButton.call();
    duration.should.be.bignumber.equal(new BN(31000000));

    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isFalse(overdueStatus);

    let erc20Supply = await erc20token.totalSupply.call();
    let approveERC20 = await erc20token.approve(
      tokenDistributor.address, erc20Supply,
      {from: owner}).should.be.fulfilled;

    let nftApproval = await erc721token.setApprovalForAll(
      tokenDistributor.address, true,
      {from: owner}).should.be.fulfilled;

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
    address.should.be.bignumber.equal(new BN(3333));
  });

  it('should get the full erc20 share for a beneficiary after first timelock unix duration to hit button', async function () {
    var overdueStatus = await tokenDistributor.overdueButton.call();
    assert.isTrue(overdueStatus);

    let contracts = await tokenDistributor.erc20TokenContracts.call(0);
    contracts.should.be.equal(erc20token.address);

    let inheritancesBeneficiary1 = await tokenDistributor.getAllCurrentErc20Inheritances.call(beneficiary1);
    inheritancesBeneficiary1[0].should.be.bignumber.equal(new BN(333333));
  });

  it('becomes overdue for remaining assets', async function () {
    await increaseTime(100);
    var overdueStatus = await tokenDistributor.overdueBeneficiaryOpenRemainingAssets.call();
    assert.isTrue(overdueStatus);
  });

  it('should get the full eth share for a beneficiary after second timelock unix duration to hit button', async function () {
    let address = await tokenDistributor.calculateBeneficiariesCurrentEthAllowance.call(beneficiary1);
    address.should.be.bignumber.equal(new BN(fullETHShare));
  });

  it('should get the full erc20 share for a beneficiary after second timelock unix duration to hit button', async function () {
    let inheritancesBeneficiary1 = await tokenDistributor.getAllCurrentErc20Inheritances.call(beneficiary1);
    inheritancesBeneficiary1[0].should.be.bignumber.equal(new BN(fullERC20Share));
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
    beneficiaryBalance.should.be.bignumber.equal(new BN(fullERC20Share));

    let tokenHolder721NewId101 =  await erc721token.ownerOf.call(101);
    tokenHolder721NewId101.should.be.equal(beneficiary2);


    let tokenHolder721NewId2 =  await erc721token.ownerOf.call(2);
    tokenHolder721NewId2.should.be.equal(beneficiary2);
  });
});

