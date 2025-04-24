// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ArrayUtils {
    function removeElement(uint[] storage array, uint index) internal {
        require(index < array.length, "Index out of bounds");
        array[index] = array[array.length - 1];
        array.pop();
    }

    function removeAddress(address[] storage array, address addr) internal returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                array[i] = array[array.length - 1];
                array.pop();
                return true;
            }
        }
        return false;
    }

    function contains(address[] storage array, address addr) internal view returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function sort(uint[] memory array) internal pure returns (uint[] memory) {
        uint[] memory sorted = new uint[](array.length);
        for (uint i = 0; i < array.length; i++) {
            sorted[i] = array[i];
        }
        
        for (uint i = 0; i < sorted.length - 1; i++) {
            for (uint j = i + 1; j < sorted.length; j++) {
                if (sorted[i] < sorted[j]) {
                    uint temp = sorted[i];
                    sorted[i] = sorted[j];
                    sorted[j] = temp;
                }
            }
        }
        return sorted;
    }
} 