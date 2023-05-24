import { BytesLike } from "@ethersproject/bytes";
import fs from "fs";
import response from "./finish_epoch_response.json";

interface OutputValidityProof {
    inputIndex: number;
    outputIndex: number;
    outputHashesRootHash: BytesLike;
    outputsEpochRootHash: BytesLike;
    machineStateHash: BytesLike;
    keccakInHashesSiblings: BytesLike[];
    outputHashesInEpochSiblings: BytesLike[];
}

function constructProof(positionIndex: number): OutputValidityProof {
    let v = response.proofs[positionIndex].validity;
    let keccakInHashesSiblingsRawData = v.keccakInHashesSiblings;
    let outputHashesInEpochSiblingsRawData = v.outputHashesInEpochSiblings;
    var keccakInHashesSiblings: BytesLike[] = [];
    var outputHashesInEpochSiblings: BytesLike[] = [];

    keccakInHashesSiblingsRawData.forEach((element) => {
        keccakInHashesSiblings.push(element.data);
    });
    outputHashesInEpochSiblingsRawData.forEach((element) => {
        outputHashesInEpochSiblings.push(element.data);
    });

    return {
        inputIndex: Number(v.inputIndex),
        outputIndex: Number(v.outputIndex),
        outputHashesRootHash: v.outputHashesRootHash.data,
        outputsEpochRootHash: v.noticesEpochRootHash.data, // FIXME
        machineStateHash: v.machineStateHash.data,
        keccakInHashesSiblings: keccakInHashesSiblings,
        outputHashesInEpochSiblings: outputHashesInEpochSiblings,
    };
}

function generateSolidityCode(
    v: OutputValidityProof,
    libraryName: string
): string {
    const array1 = v.keccakInHashesSiblings;
    const array2 = v.outputHashesInEpochSiblings;
    const lines: string[] = [
        "// SPDX-License-Identifier: UNLICENSED",
        "",
        "pragma solidity ^0.8.8;",
        "",
        "// THIS FILE WAS AUTOMATICALLY GENERATED BY `genProofLibraries.ts`.",
        "",
        'import {OutputValidityProof} from "contracts/library/LibOutputValidation.sol";',
        "",
        `library ${libraryName} {`,
        "    function getProof() internal pure returns (OutputValidityProof memory) {",
        `        uint256[${array1.length}] memory array1 = [${array1}];`,
        `        uint256[${array2.length}] memory array2 = [${array2}];`,
        `        bytes32[] memory keccakInHashesSiblings = new bytes32[](${array1.length});`,
        `        bytes32[] memory outputHashesInEpochSiblings = new bytes32[](${array2.length});`,
        `        for (uint256 i; i < ${array1.length}; ++i) { keccakInHashesSiblings[i] = bytes32(array1[i]); }`,
        `        for (uint256 i; i < ${array2.length}; ++i) { outputHashesInEpochSiblings[i] = bytes32(array2[i]); }`,
        `        return OutputValidityProof({`,
        `            inputIndex: ${v.inputIndex},`,
        `            outputIndex: ${v.outputIndex},`,
        `            outputHashesRootHash: ${v.outputHashesRootHash},`,
        `            outputsEpochRootHash: ${v.outputsEpochRootHash},`,
        `            machineStateHash: ${v.machineStateHash},`,
        "            keccakInHashesSiblings: keccakInHashesSiblings,",
        "            outputHashesInEpochSiblings: outputHashesInEpochSiblings",
        "        });",
        "    }",
        "}",
        "",
    ];
    return lines.join("\n");
}

let pairs = response.proofs.length / 2; // need to half because there's a voucher proof and notice proof for each input

// set up proofs
let noticeProofs: OutputValidityProof[] = new Array(pairs);
for (let i = 0; i < response.proofs.length; i++) {
    let inputIndex = Number(response.proofs[i].inputIndex);
    if (response.proofs[i].outputEnum == "NOTICE") {
        noticeProofs[inputIndex] = constructProof(i);
    }
}

// write to solidity library codes
for (let i = 0; i < pairs; i++) {
    let libraryName = `LibOutputProof${i}`;
    let solidityCode = generateSolidityCode(
        noticeProofs[i],
        libraryName
    );
    let fileName = `${__dirname}/${libraryName}.sol`;
    fs.writeFile(fileName, solidityCode, (err: any) => {
        if (err) throw err;
        console.log(`File '${fileName}' was generated.`);
    });
}
