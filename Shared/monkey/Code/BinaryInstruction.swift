//
//  BinaryInstructions.swift
//  monkey-swift
//
//  Created by zhejun chen on 2022/12/27.
//

import Foundation

typealias BinaryInstructions = Data

extension BinaryInstructions {
    func string() -> String {
        var readPosition = 0
        var str = ""
        while readPosition < count {
            guard let code = OpCode(rawValue: self[readPosition]) else {
                return "Error - Invaild code value: \(self[readPosition])"
            }

            guard let def = Code.definitions[code] else {
                return "Error - Can not find definition from code: \(code)"
            }

            readPosition += 1
            let (operands, readLength) = Code.readOperands(definition: def, instruction: self[readPosition...])
            readPosition += readLength

            str += "\(Code.readableInstructionString(definition: def, operands: operands) ?? "") "
        }

        return str
    }
}
