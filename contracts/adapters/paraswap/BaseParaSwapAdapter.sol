// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {DataTypes} from '@vebank/core-v1/contracts/protocol/libraries/types/DataTypes.sol';
import {FlashLoanReceiverBase} from '@vebank/core-v1/contracts/flashloan/base/FlashLoanReceiverBase.sol';
import {GPv2SafeVIP180} from '@vebank/core-v1/contracts/dependencies/gnosis/contracts/GPv2SafeVIP180.sol';
import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';
import {IVIP180Detailed} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180Detailed.sol';
import {IVIP180WithPermit} from '@vebank/core-v1/contracts/interfaces/IVIP180WithPermit.sol';
import {IPoolAddressesProvider} from '@vebank/core-v1/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleGetter} from '@vebank/core-v1/contracts/interfaces/IPriceOracleGetter.sol';
import {SafeMath} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/SafeMath.sol';
import {Ownable} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title BaseParaSwapAdapter
 * @notice Utility functions for adapters using ParaSwap
 * @author Jason Raymond Bell
 */
abstract contract BaseParaSwapAdapter is FlashLoanReceiverBase, Ownable {
  using SafeMath for uint256;
  using GPv2SafeVIP180 for IVIP180;
  using GPv2SafeVIP180 for IVIP180Detailed;
  using GPv2SafeVIP180 for IVIP180WithPermit;

  struct PermitSignature {
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  // Max slippage percent allowed
  uint256 public constant MAX_SLIPPAGE_PERCENT = 3000; // 30%

  IPriceOracleGetter public immutable ORACLE;

  event Swapped(
    address indexed fromAsset,
    address indexed toAsset,
    uint256 fromAmount,
    uint256 receivedAmount
  );
  event Bought(
    address indexed fromAsset,
    address indexed toAsset,
    uint256 amountSold,
    uint256 receivedAmount
  );

  constructor(IPoolAddressesProvider addressesProvider) FlashLoanReceiverBase(addressesProvider) {
    ORACLE = IPriceOracleGetter(addressesProvider.getPriceOracle());
  }

  /**
   * @dev Get the price of the asset from the oracle denominated in eth
   * @param asset address
   * @return eth price for the asset
   */
  function _getPrice(address asset) internal view returns (uint256) {
    return ORACLE.getAssetPrice(asset);
  }

  /**
   * @dev Get the decimals of an asset
   * @return number of decimals of the asset
   */
  function _getDecimals(IVIP180Detailed asset) internal view returns (uint8) {
    uint8 decimals = asset.decimals();
    // Ensure 10**decimals won't overflow a uint256
    require(decimals <= 77, 'TOO_MANY_DECIMALS_ON_TOKEN');
    return decimals;
  }

  /**
   * @dev Get the aToken associated to the asset
   * @return address of the aToken
   */
  function _getReserveData(address asset) internal view returns (DataTypes.ReserveData memory) {
    return POOL.getReserveData(asset);
  }

  function _pullATokenAndWithdraw(
    address reserve,
    address user,
    uint256 amount,
    PermitSignature memory permitSignature
  ) internal {
    IVIP180WithPermit reserveAToken = IVIP180WithPermit(
      _getReserveData(address(reserve)).aTokenAddress
    );
    _pullATokenAndWithdraw(reserve, reserveAToken, user, amount, permitSignature);
  }

  /**
   * @dev Pull the ATokens from the user
   * @param reserve address of the asset
   * @param reserveAToken address of the aToken of the reserve
   * @param user address
   * @param amount of tokens to be transferred to the contract
   * @param permitSignature struct containing the permit signature
   */
  function _pullATokenAndWithdraw(
    address reserve,
    IVIP180WithPermit reserveAToken,
    address user,
    uint256 amount,
    PermitSignature memory permitSignature
  ) internal {
    // If deadline is set to zero, assume there is no signature for permit
    if (permitSignature.deadline != 0) {
      reserveAToken.permit(
        user,
        address(this),
        permitSignature.amount,
        permitSignature.deadline,
        permitSignature.v,
        permitSignature.r,
        permitSignature.s
      );
    }

    // transfer from user to adapter
    reserveAToken.safeTransferFrom(user, address(this), amount);

    // withdraw reserve
    require(POOL.withdraw(reserve, amount, address(this)) == amount, 'UNEXPECTED_AMOUNT_WITHDRAWN');
  }

  /**
   * @dev Emergency rescue for token stucked on this contract, as failsafe mechanism
   * - Funds should never remain in this contract more time than during transactions
   * - Only callable by the owner
   */
  function rescueTokens(IVIP180 token) external onlyOwner {
    token.safeTransfer(owner(), token.balanceOf(address(this)));
  }
}
