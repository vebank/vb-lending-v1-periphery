// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Ownable} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/Ownable.sol';
import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';

contract MockParaSwapTokenTransferProxy is Ownable {
  function transferFrom(
    address token,
    address from,
    address to,
    uint256 amount
  ) external onlyOwner {
    IVIP180(token).transferFrom(from, to, amount);
  }
}
