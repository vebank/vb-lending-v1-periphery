// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Address} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/Address.sol';
import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';

import {IPoolAddressesProvider} from '@vebank/core-v1/contracts/interfaces/IPoolAddressesProvider.sol';
import {IPool} from '@vebank/core-v1/contracts/interfaces/IPool.sol';
import {GPv2SafeVIP180} from '@vebank/core-v1/contracts/dependencies/gnosis/contracts/GPv2SafeVIP180.sol';
import {ReserveConfiguration} from '@vebank/core-v1/contracts/protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '@vebank/core-v1/contracts/protocol/libraries/types/DataTypes.sol';

/**
 * @title WalletBalanceProvider contract
 * @author VeBank, influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE VeBank PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the VeBank backend.
 **/
contract WalletBalanceProvider {
  using Address for address payable;
  using Address for address;
  using GPv2SafeVIP180 for IVIP180;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  address constant MOCK_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
    @dev Fallback function, don't accept any ETH
    **/
  receive() external payable {
    //only contracts can send ETH to the core
    require(msg.sender.isContract(), '22');
  }

  /**
    @dev Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
  function balanceOf(address user, address token) public view returns (uint256) {
    if (token == MOCK_ETH_ADDRESS) {
      return user.balance; // ETH balance
      // check if token is actually a contract
    } else if (token.isContract()) {
      return IVIP180(token).balanceOf(user);
    }
    revert('INVALID_TOKEN');
  }

  /**
   * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
   * @param users The list of users
   * @param tokens The list of tokens
   * @return And array with the concatenation of, for each user, his/her balances
   **/
  function batchBalanceOf(address[] calldata users, address[] calldata tokens)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = balanceOf(users[i], tokens[j]);
      }
    }

    return balances;
  }

  /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
  function getUserWalletBalances(address provider, address user)
    external
    view
    returns (address[] memory, uint256[] memory)
  {
    IPool pool = IPool(IPoolAddressesProvider(provider).getPool());

    address[] memory reserves = pool.getReservesList();
    address[] memory reservesWithEth = new address[](reserves.length + 1);
    for (uint256 i = 0; i < reserves.length; i++) {
      reservesWithEth[i] = reserves[i];
    }
    reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;

    uint256[] memory balances = new uint256[](reservesWithEth.length);

    for (uint256 j = 0; j < reserves.length; j++) {
      DataTypes.ReserveConfigurationMap memory configuration = pool.getConfiguration(
        reservesWithEth[j]
      );

      (bool isActive, , , , ) = configuration.getFlags();

      if (!isActive) {
        balances[j] = 0;
        continue;
      }
      balances[j] = balanceOf(user, reservesWithEth[j]);
    }
    balances[reserves.length] = balanceOf(user, MOCK_ETH_ADDRESS);

    return (reservesWithEth, balances);
  }
}
