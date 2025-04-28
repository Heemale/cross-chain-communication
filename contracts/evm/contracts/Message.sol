// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Message {
    struct MoveStruct {
        bytes packageId; // 16进制转bytes
        bytes moduleId; // 16进制转bytes
        bytes funcStructId; // 字符串转16进制，再转bytes
    }

    // WARN!!! 当typ为10,object类型时，该object必须是共享类型，否则不予执行
    struct MoveCallArg {
        uint8 typ; // 0-留空;1-u8;2-u16;3-u32;4-u64;5-u128;6-u256;7-bool;8-address;9-string;10-object;11-vector<u8>;255-SUI(原生代币,当为255时,data为数量的十六进制转bytes)
        bytes data;
    }

    struct MoveCall {
        MoveStruct target;
        MoveStruct[] types;
        MoveCallArg[] args;
    }

    function encodeMoveStruct(MoveStruct memory ms)
    public
    pure
    returns (bytes memory)
    {
        uint256 moduleIdLen = ms.moduleId.length;
        uint256 funcStructIdLen = ms.funcStructId.length;
        return
            bytes.concat(
            ms.packageId,
            abi.encodePacked(moduleIdLen),
            ms.moduleId,
            abi.encodePacked(funcStructIdLen),
            ms.funcStructId
        );
    }

    function encodeMoveStruct(
        bytes memory packageId,
        bytes memory moduleId,
        bytes memory funcStructId
    ) public pure returns (bytes memory) {
        return encodeMoveStruct(MoveStruct(packageId, moduleId, funcStructId));
    }

    function decodeMoveStruct(bytes memory bs)
    public
    pure
    returns (MoveStruct memory ms)
    {
        uint256 packageIdLen = 32;
        bytes memory packageId = new bytes(packageIdLen);
        for (uint256 index = 0; index < packageIdLen; index++) {
            packageId[index] = bs[index];
        }

        uint256 offset = 32;

        uint256 moduleIdLen = abi.decode(
            splitBytes(bs, offset, offset + 32),
            (uint256)
        );

        offset += 32;

        bytes memory moduleId = splitBytes(bs, offset, offset + moduleIdLen);

        offset += moduleIdLen;

        uint256 funcStructIdLen = abi.decode(
            splitBytes(bs, offset, offset + 32),
            (uint256)
        );

        offset += 32;

        bytes memory funcStructId = splitBytes(
            bs,
            offset,
            offset + funcStructIdLen
        );

        return MoveStruct(packageId, moduleId, funcStructId);
    }

    function encodeMoveCallArg(MoveCallArg memory arg)
    public
    pure
    returns (bytes memory)
    {
        return bytes.concat(abi.encodePacked(arg.typ), arg.data);
    }

    function encodeMoveCallArg(uint8 typ, bytes memory data)
    public
    pure
    returns (bytes memory)
    {
        return encodeMoveCallArg(MoveCallArg(typ, data));
    }

    function decodeMoveCallArg(bytes memory bs)
    public
    pure
    returns (MoveCallArg memory)
    {
        uint8 typ = uint8(bs[0]);
        uint256 offset = 1;
        bytes memory dataBytes = new bytes(bs.length - offset); // uint256, 32字节
        for (uint256 index = 0; index < dataBytes.length; index++) {
            dataBytes[index] = bs[offset + index];
        }
        return MoveCallArg(typ, dataBytes);
    }

    function encodeMoveCall(MoveCall memory call)
    public
    pure
    returns (bytes memory)
    {
        bytes memory targetBytes = encodeMoveStruct(call.target);
        bytes[] memory typesBytes = new bytes[](call.types.length);
        for (uint256 index = 0; index < typesBytes.length; index++) {
            typesBytes[index] = encodeMoveStruct(call.types[index]);
        }
        bytes[] memory argsBytes = new bytes[](call.args.length);
        for (uint256 index = 0; index < argsBytes.length; index++) {
            argsBytes[index] = encodeMoveCallArg(call.args[index]);
        }

        bytes memory result = bytes.concat(
            abi.encodePacked(targetBytes.length),
            targetBytes,
            abi.encodePacked(typesBytes.length)
        );

        for (uint256 index = 0; index < typesBytes.length; index++) {
            result = bytes.concat(
                result,
                abi.encodePacked(typesBytes[index].length),
                typesBytes[index]
            );
        }

        result = bytes.concat(result, abi.encodePacked(argsBytes.length));

        for (uint256 index = 0; index < argsBytes.length; index++) {
            result = bytes.concat(
                result,
                abi.encodePacked(argsBytes[index].length),
                argsBytes[index]
            );
        }

        return result;
    }

    function encodeMoveCall(
        bytes memory packageId,
        bytes memory moduleId,
        bytes memory funcId,
        bytes[] memory typePackageIds,
        bytes[] memory typeModules,
        bytes[] memory typeStructIds,
        uint8[] memory argTypes,
        bytes[] memory argDatas
    ) public pure returns (bytes memory) {
        MoveStruct memory target = MoveStruct(packageId, moduleId, funcId);

        MoveStruct[] memory types = new MoveStruct[](typeModules.length);
        for (uint256 index = 0; index < typeModules.length; index++) {
            MoveStruct memory typ = MoveStruct(
                typePackageIds[index],
                typeModules[index],
                typeStructIds[index]
            );
            types[index] = typ;
        }

        MoveCallArg[] memory args = new MoveCallArg[](argTypes.length);
        for (uint256 index = 0; index < argTypes.length; index++) {
            MoveCallArg memory mcr = MoveCallArg(
                argTypes[index],
                argDatas[index]
            );
            args[index] = mcr;
        }

        MoveCall memory mc = MoveCall(target, types, args);
        return encodeMoveCall(mc);
    }

    function decodeMoveCall(bytes memory bs)
    public
    pure
    returns (MoveCall memory)
    {
        uint256 offset = 0;

        uint256 targetBytesLen = abi.decode(
            splitBytes(bs, offset, 32),
            (uint256)
        ); // uint256 32字节

        offset = 32;

        bytes memory targetBytes = splitBytes(
            bs,
            offset,
            offset + targetBytesLen
        );

        offset += targetBytesLen;

        uint256 typesBytesArrayLen = abi.decode(
            splitBytes(bs, offset, offset + 32),
            (uint256)
        );

        offset += 32;

        MoveStruct[] memory types = new MoveStruct[](typesBytesArrayLen);

        for (uint256 index = 0; index < typesBytesArrayLen; index++) {
            uint256 typesBytesLen = abi.decode(
                splitBytes(bs, offset, offset + 32),
                (uint256)
            );

            offset += 32;

            bytes memory typeBytes = splitBytes(
                bs,
                offset,
                offset + typesBytesLen
            );

            offset += typesBytesLen;

            types[index] = decodeMoveStruct(typeBytes);
        }

        uint256 argsBytesArrayLen = abi.decode(
            splitBytes(bs, offset, offset + 32),
            (uint256)
        );

        offset += 32;
        MoveCallArg[] memory args = new MoveCallArg[](argsBytesArrayLen);
        for (uint256 index = 0; index < argsBytesArrayLen; index++) {
            uint256 argsBytesLen = abi.decode(
                splitBytes(bs, offset, offset + 32),
                (uint256)
            );

            offset += 32;

            bytes memory argBytes = splitBytes(
                bs,
                offset,
                offset + argsBytesLen
            );

            offset += argsBytesLen;

            args[index] = decodeMoveCallArg(argBytes);
        }

        return MoveCall(decodeMoveStruct(targetBytes), types, args);
    }

    function splitBytes(
        bytes memory bs,
        uint256 start,
        uint256 end
    ) public pure returns (bytes memory result) {
        result = new bytes(end - start);
        for (uint256 index = 0; index < result.length; index++) {
            result[index] = bs[start + index];
        }
    }
}
