// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPullRewardsTransferStrategy} from '../interfaces/IPullRewardsTransferStrategy.sol';
import {ITransferStrategyBase} from '../interfaces/ITransferStrategyBase.sol';
import {TransferStrategyBase} from './TransferStrategyBase.sol';
import {GPv2SafeVIP180} from '@vebank/core-v1/contracts/dependencies/gnosis/contracts/GPv2SafeVIP180.sol';
import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';

/**
 * @title PullRewardsTransferStrategy
 * @notice Transfer strategy that pulls VIP180 rewards from an external account to the user address.
 * The external account could be a smart contract or EOA that must approve to the PullRewardsTransferStrategy contract address.
 * @author VeBank
 **/
contract PullRewardsTransferStrategy is TransferStrategyBase, IPullRewardsTransferStrategy {
  using GPv2SafeVIP180 for IVIP180;

  address internal immutable REWARDS_VAULT;

  constructor(
    address incentivesController,
    address rewardsAdmin,
    address rewardsVault
  ) TransferStrategyBase(incentivesController, rewardsAdmin) {
    REWARDS_VAULT = rewardsVault;
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
    IVIP180(reward).safeTransferFrom(REWARDS_VAULT, to, amount);

    return true;
  }

  /// @inheritdoc IPullRewardsTransferStrategy
  function getRewardsVault() external view returns (address) {
    return REWARDS_VAULT;
  }
}
