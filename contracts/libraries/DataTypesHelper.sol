// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';
import {DataTypes} from '@vebank/core-v1/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * @title DataTypesHelper
 * @author VeBank
 * @dev Helper library to track user current debt balance, used by WETHGateway
 */
library DataTypesHelper {
  /**
   * @notice Fetches the user current stable and variable debt balances
   * @param user The user address
   * @param reserve The reserve data object
   * @return The stable debt balance
   * @return The variable debt balance
   **/
  function getUserCurrentDebt(address user, DataTypes.ReserveData memory reserve)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IVIP180(reserve.stableDebtTokenAddress).balanceOf(user),
      IVIP180(reserve.variableDebtTokenAddress).balanceOf(user)
    );
  }
}
