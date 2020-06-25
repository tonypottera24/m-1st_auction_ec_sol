// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct SameDLProof {
    BigNumber.instance t1;
    BigNumber.instance t2;
    BigNumber.instance r;
}

library SameDLProofLib {
    using BigNumberLib for BigNumber.instance;
    using CtLib for Ct;
    using CtLib for Ct[];

    function valid(
        SameDLProof memory pi,
        BigNumber.instance memory g1,
        BigNumber.instance memory g2,
        BigNumber.instance memory y1,
        BigNumber.instance memory y2,
        BigNumber.instance memory p,
        BigNumber.instance memory q
    ) internal view returns (bool) {
        // (pi.t1, pi.t2) = (pi.t1.mod(p), pi.t2.mod(p));
        // pi.r = pi.r.mod(q);
        // (g1, g2) = (g1.mod(p), g2.mod(p));
        // (y1, y2) = (y1.mod(p), y2.mod(p));

        // bytes memory pack = new bytes(
        //     g1.val.length +
        //         g2.val.length +
        //         y1.val.length +
        //         y2.val.length +
        //         pi.t1.val.length +
        //         pi.t2.val.length
        // );
        // uint256 offset = 0;
        // for (uint256 i = 0; i < g1.val.length; i++) pack[i] = g1.val[i];
        // offset += g1.val.length;
        // for (uint256 i = 0; i < g2.val.length; i++)
        //     pack[i + offset] = g2.val[i];
        // offset += g2.val.length;
        // for (uint256 i = 0; i < y1.val.length; i++)
        //     pack[i + offset] = y1.val[i];
        // offset += y1.val.length;
        // for (uint256 i = 0; i < y2.val.length; i++)
        //     pack[i + offset] = y2.val[i];
        // offset += y2.val.length;
        // for (uint256 i = 0; i < pi.t1.val.length; i++)
        //     pack[i + offset] = pi.t1.val[i];
        // offset += pi.t1.val.length;
        // for (uint256 i = 0; i < pi.t2.val.length; i++)
        //     pack[i + offset] = pi.t2.val[i];

        bytes32 digest = keccak256(
            // pack
            abi.encodePacked(
                g1.val,
                g2.val,
                y1.val,
                y2.val,
                pi.t1.val,
                pi.t2.val
            )
        );
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if (digest >> i > 0) bit_length++;
            else break;
        }
        bytes memory digest_packed = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            digest_packed[i] = digest[i];
        }
        BigNumber.instance memory c = BigNumber
            .instance(digest_packed, false, bit_length)
            .mod(q);
        return valid_pack(pi, g1, g2, y1, y2, p, c);
    }

    function valid_pack(
        SameDLProof memory pi,
        BigNumber.instance memory g1,
        BigNumber.instance memory g2,
        BigNumber.instance memory y1,
        BigNumber.instance memory y2,
        BigNumber.instance memory p,
        BigNumber.instance memory c
    ) internal view returns (bool) {
        BigNumber.instance memory tt1 = g1.pow(pi.r, p).mul(y1.pow(c, p), p);
        bool a1 = pi.t1.equals(tt1, p);
        BigNumber.instance memory tt2 = g2.pow(pi.r, p).mul(y2.pow(c, p), p);
        bool a2 = pi.t2.equals(tt2, p);
        return a1 && a2;
    }

    function valid(
        SameDLProof[] memory pi,
        BigNumber.instance[] memory g1,
        BigNumber.instance[] memory g2,
        BigNumber.instance[] memory y1,
        BigNumber.instance[] memory y2,
        BigNumber.instance memory p,
        BigNumber.instance memory q
    ) internal view returns (bool) {
        require(
            pi.length == g1.length &&
                pi.length == g2.length &&
                pi.length == y1.length &&
                pi.length == y2.length,
            "The length of g1, g2, y1, y2 and pi must be same."
        );
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i], p, q) == false)
                return false;
        }
        return true;
    }
}