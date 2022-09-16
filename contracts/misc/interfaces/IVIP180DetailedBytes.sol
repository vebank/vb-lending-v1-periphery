// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IVIP180} from '@vebank/core-v1/contracts/dependencies/openzeppelin/contracts/IVIP180.sol';

interface IVIP180DetailedBytes is IVIP180 {
  function name() external view returns (bytes32);

  function symbol() external view returns (bytes32);

  function decimals() external view returns (uint8);
}