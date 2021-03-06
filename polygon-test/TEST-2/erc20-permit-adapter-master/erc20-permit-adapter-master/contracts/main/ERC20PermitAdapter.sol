//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./externals/Counter.sol";
import "./externals/interfaces/IERC20.sol";
import "./externals/ECDSA.sol";

import "./externals/interfaces/IERC20PermitAdapter.sol";

contract ERC20PermitAdapter is IERC20PermitAdapter {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    function transferFrom(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    ) external override {
        require(
            block.timestamp <= deadline,
            "ERC20EIP2612Adapter: expired deadline"
        );

        bytes32 permitHash =
            keccak256(
                abi.encode(
                    asset,
                    msg.sender,
                    amount,
                    deadline,
                    _nonces[from].current()
                )
            );

        address signer =
            ECDSA.recover(ECDSA.toEthSignedMessageHash(permitHash), signature);

        require(signer == from, "ERC20EIP2612Adapter: invalid signature");

        require(IERC20(asset).transferFrom(from, to, amount));
        _nonces[from].increment();
    }

    // Getters

    function nonceOf(address account) external view override returns (uint256) {
        return _nonces[account].current();
    }
}
