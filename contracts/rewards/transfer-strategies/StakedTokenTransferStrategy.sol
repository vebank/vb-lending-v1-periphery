// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IStakedToken} from '../interfaces/IStakedToken.sol';
import {IStakedTokenTransferStrategy} from '../interfaces/IStakedTokenTransferStrategy.sol';
import {ITransferStrategyBase} from '../interfaces/ITransferStrategyBase.sol';
import {TransferStrategyBase} from './TransferStrategyBase.sol';
import {GPv2SafeVIP180} from '@vebank/core-v1/contracts/dependencies/gnosis/contracts/GPv2SafeVIP180.sol';
import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';

/**
 * @title StakedTokenTransferStrategy
 * @notice Transfer strategy that stakes the rewards into a staking contract and transfers the staking contract token.
 * The underlying token must be transferred to this contract to be able to stake it on demand.
 * @author VeBank
 **/
contract StakedTokenTransferStrategy is TransferStrategyBase, IStakedTokenTransferStrategy {
  using GPv2SafeVIP180 for IVIP180;

  IStakedToken internal immutable STAKE_CONTRACT;
  address internal immutable UNDERLYING_TOKEN;

  constructor(
    address incentivesController,
    address rewardsAdmin,
    IStakedToken stakeToken
  ) TransferStrategyBase(incentivesController, rewardsAdmin) {
    STAKE_CONTRACT = stakeToken;
    UNDERLYING_TOKEN = STAKE_CONTRACT.STAKED_TOKEN();

    IVIP180(UNDERLYING_TOKEN).approve(address(STAKE_CONTRACT), 0);
    IVIP180(UNDERLYING_TOKEN).approve(address(STAKE_CONTRACT), type(uint256).max);
  }

  /// @inheritdoc TransferStrategyBase
  function performTransfer(
    address to,
    address reward,
    uint256 amount
  )
    external
    override(TransferStrategyBase, ITransferStrategyBase)
    onlyIncentivesController
    returns (bool)
  {
    require(reward == address(STAKE_CONTRACT), 'REWARD_TOKEN_NOT_STAKE_CONTRACT');

    STAKE_CONTRACT.stake(to, amount);

    return true;
  }

  /// @inheritdoc IStakedTokenTransferStrategy
  function renewApproval() external onlyRewardsAdmin {
    IVIP180(UNDERLYING_TOKEN).approve(address(STAKE_CONTRACT), 0);
    IVIP180(UNDERLYING_TOKEN).approve(address(STAKE_CONTRACT), type(uint256).max);
  }

  /// @inheritdoc IStakedTokenTransferStrategy
  function dropApproval() external onlyRewardsAdmin {
    IVIP180(UNDERLYING_TOKEN).approve(address(STAKE_CONTRACT), 0);
  }

  /// @inheritdoc IStakedTokenTransferStrategy
  function getStakeContract() external view returns (address) {
    return address(STAKE_CONTRACT);
  }

  /// @inheritdoc IStakedTokenTransferStrategy
  function getUnderlyingToken() external view returns (address) {
    return UNDERLYING_TOKEN;
  }
}
