// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {ITransferStrategyBase} from '../rewards/interfaces/ITransferStrategyBase.sol';
import {TransferStrategyBase} from '../rewards/transfer-strategies/TransferStrategyBase.sol';
import {GPv2SafeVIP180} from '@vebank/core-v1/contracts/dependencies/gnosis/contracts/GPv2SafeVIP180.sol';
import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';

/**
 * @title MockBadTransferStrategy
 * @notice Transfer strategy that always return false at performTransfer and does noop.
 * @author VeBank
 **/
contract MockBadTransferStrategy is TransferStrategyBase {
  using GPv2SafeVIP180 for IVIP180;

  // Added storage variable to prevent warnings at compilation for performTransfer
  uint256 ignoreWarning;

  constructor(address incentivesController, address rewardsAdmin)
    TransferStrategyBase(incentivesController, rewardsAdmin)
  {}

  /// @inheritdoc TransferStrategyBase
  function performTransfer(
    address,
    address,
    uint256
  ) external override onlyIncentivesController returns (bool) {
    ignoreWarning = 1;
    return false;
  }
}
