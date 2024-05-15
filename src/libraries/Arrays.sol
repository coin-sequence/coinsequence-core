// SPDX-License-Identifier: MIT
// Code taken from OpenZeppelin Contracts (last updated v5.0.0) (utils/Arrays.sol)
// solhint-disable no-inline-assembly
pragma solidity 0.8.25;

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
	/**
	 * @dev Sort an array of bytes32 (in memory) following the provided comparator function.
	 *
	 * This function does the sorting "in place", meaning that it overrides the input. The object is returned for
	 * convenience, but that returned value can be discarded safely if the caller has a memory pointer to the array.
	 *
	 * NOTE: this function's cost is `O(n · log(n))` in average and `O(n²)` in the worst case, with n the length of the
	 * array. Using it in view functions that are executed through `eth_call` is safe, but one should be very careful
	 * when executing this as part of a transaction. If the array being sorted is too large, the sort operation may
	 * consume more gas than is available in a block, leading to potential DoS.
	 */
	function _sort(bytes32[] memory array, function(bytes32, bytes32) pure returns (bool) comp) internal pure returns (bytes32[] memory) {
		_quickSort(_begin(array), _end(array), comp);
		return array;
	}

	/**
	 * @dev Variant of {sort} that sorts an array of address in increasing order.
	 */
	function _sort(address[] memory array) internal pure returns (address[] memory) {
		_sort(_castToBytes32Array(array), _defaultComp);
		return array;
	}

	/**
	 * @dev Performs a quick sort of a segment of memory. The segment sorted starts at `begin` (inclusive), and stops
	 * at end (exclusive). Sorting follows the `comp` comparator.
	 *
	 * Invariant: `begin <= end`. This is the case when initially called by {sort} and is preserved in subcalls.
	 *
	 * IMPORTANT: Memory locations between `begin` and `end` are not validated/zeroed. This function should
	 * be used only if the limits are within a memory array.
	 */
	function _quickSort(uint256 begin, uint256 end, function(bytes32, bytes32) pure returns (bool) comp) private pure {
		unchecked {
			if (end - begin < 0x40) return;

			// Use first element as pivot
			bytes32 pivot = _mload(begin);
			// Position where the pivot should be at the end of the loop
			uint256 pos = begin;

			for (uint256 it = begin + 0x20; it < end; it += 0x20) {
				if (comp(_mload(it), pivot)) {
					// If the value stored at the iterator's position comes before the pivot, we increment the
					// position of the pivot and move the value there.
					pos += 0x20;
					_swap(pos, it);
				}
			}

			_swap(begin, pos); // Swap pivot into place
			_quickSort(begin, pos, comp); // Sort the left side of the pivot
			_quickSort(pos + 0x20, end, comp); // Sort the right side of the pivot
		}
	}

	/**
	 * @dev Pointer to the memory location of the first element of `array`.
	 */
	function _begin(bytes32[] memory array) private pure returns (uint256 ptr) {
		/// @solidity memory-safe-assembly
		assembly {
			ptr := add(array, 0x20)
		}
	}

	/**
	 * @dev Pointer to the memory location of the first memory word (32bytes) after `array`. This is the memory word
	 * that comes just after the last element of the array.
	 */
	function _end(bytes32[] memory array) private pure returns (uint256 ptr) {
		unchecked {
			return _begin(array) + array.length * 0x20;
		}
	}

	/**
	 * @dev Load memory word (as a bytes32) at location `ptr`.
	 */
	function _mload(uint256 ptr) private pure returns (bytes32 value) {
		assembly {
			value := mload(ptr)
		}
	}

	/**
	 * @dev Swaps the elements memory location `ptr1` and `ptr2`.
	 */
	function _swap(uint256 ptr1, uint256 ptr2) private pure {
		assembly {
			let value1 := mload(ptr1)
			let value2 := mload(ptr2)
			mstore(ptr1, value2)
			mstore(ptr2, value1)
		}
	}

	/// @dev Comparator for sorting arrays in increasing order.
	//slither-disable-next-line dead-code
	function _defaultComp(bytes32 a, bytes32 b) private pure returns (bool) {
		return a < b;
	}

	/// @dev Helper: low level cast address memory array to uint256 memory array
	function _castToBytes32Array(address[] memory input) private pure returns (bytes32[] memory output) {
		assembly {
			output := input
		}
	}
}
