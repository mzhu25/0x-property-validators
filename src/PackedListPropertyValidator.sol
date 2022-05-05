// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IPropertyValidator.sol";

contract PackedListPropertyValidator is IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encodes a packed array of tokenIds, and a number indicating
    ///        how many bytes each tokenId in the array uses.
    function validateProperty(
        address /* tokenAddress */,
        uint256 tokenId,
        bytes calldata propertyData
    )
        external
        pure
    {
        (uint256 bytesPerTokenId, bytes memory packedList) = abi.decode(
            propertyData,
            (uint256, bytes)
        );

        require(
            bytesPerTokenId != 0 && bytesPerTokenId <= 32, 
            "PackedListPropertyValidator::validateProperty/INVALID_BYTES_PER_TOKEN_ID"
        );

        uint256 bitMask = ~(type(uint256).max << (bytesPerTokenId * 8));
        assembly {
            // Binary search for given tokenId

            let left := 1
            // right = number of tokenIds in the list
            let right := div(mload(packedList), bytesPerTokenId)

            // while(left < right)
            for {} lt(left, right) {} {
                // mid = (left + right) / 2
                let mid := div(add(left, right), 2)
                // more or less equivalent to:
                // value = list[index]
                let offset := add(packedList, mul(mid, bytesPerTokenId))
                let value := and(mload(offset), bitMask)
                // if (value < tokenId) {
                //     left = mid + 1;
                //     continue; 
                // }
                if lt(value, tokenId) {
                    left := add(mid, 1)
                    continue
                }
                // if (value > tokenId) {
                //     right = mid - 1;
                //     continue; 
                // }
                if gt(value, tokenId) {
                    right := sub(mid, 1)
                    continue
                }
                // if(packedList[mid] == tokenId) { return; }
                stop()
            }
        }
        revert("PackedListPropertyValidator::validateProperty::TOKEN_ID_NOT_FOUND_IN_LIST");
    }
}
