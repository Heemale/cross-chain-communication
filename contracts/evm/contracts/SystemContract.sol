// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Message.sol";
import "./mContract.sol";
import "./access/OwnableUpgradeable.sol";
import "./proxy/utils/UUPSUpgradeable.sol";

contract SystemContract is OwnableUpgradeable, UUPSUpgradeable {
    uint8 public constant SUI_DECIMALS = 9;
    uint8 public constant ETH_DECIMALS = 18;

    uint256 public sequence;
    uint256 public moveSequence;

    mapping(uint256 => bool) public calls;

    address payable public gasReceiver;
    address public crossChainCaller;

    event DepositAndCall(
        uint256 indexed seq,
        address indexed sender,
        uint64 callValue,
        uint64 gasPrice,
        uint64 gasLimit,
        bytes callData
    );

    event CrossChainCall(
        uint256 indexed seq,
        bool indexed success,
        address target,
        bytes data
    );

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setGasReceiver(address payable receiver) external onlyOwner {
        gasReceiver = receiver;
    }

    function setCrossChainCaller(address caller) external onlyOwner {
        crossChainCaller = caller;
    }

    function depositAndCall(
        Message.MoveCall calldata call,
        uint64 callValue, // 调用Sui链的合约时，可以将对应的SUI直接转为参数,Sui链的value
        uint64 gasPrice, // Sui链的gasPrice,Sui链的单位
        uint64 gasLimit // Sui链的gasLimit,Sui链的单位
    ) external payable {
        address sender = msg.sender;
        uint256 value = msg.value;

        uint256 count = 0;
        for (uint256 index = 0; index < call.args.length; index++) {
            if (call.args[index].typ == 255) {
                count++;
            }
            if (count > 1) {
                revert("typ 255 only 1");
            }
        }

        uint256 gas = gasPrice * gasLimit;

        require(
            value ==
            (gas + callValue) *
            10 ** (ETH_DECIMALS - SUI_DECIMALS),
            "value cal error"
        );

        sequence++;

        gasReceiver.transfer(value);

        emit DepositAndCall(
            sequence,
            sender,
            callValue,
            gasPrice,
            gasLimit,
            Message.encodeMoveCall(call)
        );
    }

    function crossChainCall(
        uint256 seq,
        address target,
        bytes memory data
    ) external payable {
        require(msg.sender == crossChainCaller, "not caller");
        require(moveSequence + 1 == seq, "valid called");
        calls[seq] = true;
        moveSequence = seq;
        (bool success,) = target.call{value: msg.value}(
            abi.encodeWithSelector(0xc49f7e8b, data)
        );
        emit CrossChainCall(seq, success, target, data);
    }
}
