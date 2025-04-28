// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./mContract.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract Test is mContract {
    IUniswapV2Router02 public uniswapRouter;

    constructor(address _router) {
        uniswapRouter = IUniswapV2Router02(_router);
    }

    function encodeMessage(
        address OriginTokenAddr,
        address SUITokenAddr,
        uint256 amountIn,
        uint256 amountOutMin,
        address receiver,
        uint256 deadline
    ) external pure returns (bytes memory) {
        return abi.encode(OriginTokenAddr, SUITokenAddr, amountIn, amountOutMin, receiver, deadline);
    }

    function decodeMessage(bytes calldata data) public pure returns (address, address, uint256, uint256, address, uint256) {
        return abi.decode(data, (address, address, uint256, uint256, address, uint256));
    }

    function onCrossChainCall(bytes calldata message)
    external
    payable
    {
        (address OriginToken, address SuiTokenAddr, uint256 amountIn, uint256 amountOutMin, address receiver, uint256 deadline) = decodeMessage(message);
        require(msg.value == amountIn, "Need to equal amount!");

        address[] memory path = new address[](2);
        path[0] = OriginToken;
        path[1] = SuiTokenAddr;

        uint256 deadLine = block.timestamp + deadline;

        // 调用ETH兑换Token
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(
            amountOutMin,
            path,
            receiver,
            deadLine
        );
    }

    receive() external payable {}
}
