// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {DLProof, DLProofLib} from "./DLProofLib.sol";

struct CtMProof {
    ECPoint ya;
    ECPoint ctCA;
    SameDLProof piA;
    DLProof piR;
}

library CtMProofLib {
    using UIntLib for uint256;
    using ECPointLib for ECPoint;
    using SameDLProofLib for SameDLProof;
    using DLProofLib for DLProof;

    function valid(
        CtMProof memory pi,
        ECPoint memory y,
        Ct memory ct,
        uint256 m
    ) internal view returns (bool) {
        ECPoint memory zm = ECPointLib.z().scalar(m);
        ECPoint memory ctC = ct.c.sub(zm);
        require(
            pi.piA.valid(y, ctC, pi.ya, pi.ctCA),
            "pi.piA is not a valid proof"
        );
        return pi.piR.valid(pi.ya, pi.ctCA);
    }

    function valid(
        CtMProof[] memory pi,
        ECPoint memory y,
        Ct[] memory ct,
        uint256 m
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], y, ct[i], m) == false) return false;
        }
        return true;
    }
}
