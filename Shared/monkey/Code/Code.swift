//
//  Code.swift
//  monkey-swift
//
//  Created by zhejun chen on 2022/12/26.
//

import Foundation

enum OpCode: UInt8 {
    case constant = 0
    case pop            // 1
    case add            // 2
    case sub            // 3
    case mutiple        // 4
    case divide         // 5
    case trueConstant   // 6
    case falseConstant  // 7
    case equal          // 8
    case notEqual       // 9
    case greaterThan    // 10
    case minus          // 11
    case bang           // 12
    case jumpNotTrurhy  // 13
    case jump           // 14
    case nullConstant   // 15
    case getGlobal      // 16
    case setGlobal      // 17
    case getLocal       // 18
    case setLocal       // 19
    case array          // 20
    case hash           // 21
    case index          // 22
    case call           // 23
    case returnValue    // 24
    case returnNone     // 25
    case getBuiltin     // 26
    case getFree        // 27
    case closure        // 28
    case currentClosure // 29
}

class Code {
    struct Definition {
        let name: String
        let operandWidths: [Int]

        init(name: String, operandWidths: [Int] = []) {
            self.name = name
            self.operandWidths = operandWidths
        }
    }

    static var definitions = [
        OpCode.constant: Definition(name: "OpConstant", operandWidths: [2]),
        OpCode.pop: Definition(name: "OpPop"),
        OpCode.add: Definition(name: "OpAdd"),
        OpCode.sub: Definition(name: "OpSub"),
        OpCode.mutiple: Definition(name: "OpMutiple"),
        OpCode.divide: Definition(name: "OpDivide"),
        OpCode.trueConstant: Definition(name: "OpTrue"),
        OpCode.falseConstant: Definition(name: "OpFalse"),
        OpCode.equal: Definition(name: "OpEqual"),
        OpCode.notEqual: Definition(name: "OpNotEqual"),
        OpCode.greaterThan: Definition(name: "OpGreaterThan"),
        OpCode.minus: Definition(name: "OpMinus"),
        OpCode.bang: Definition(name: "OpBang"),
        OpCode.jumpNotTrurhy: Definition(name: "OpJumpNotTrurhy", operandWidths: [2]),
        OpCode.jump: Definition(name: "OpJump", operandWidths: [2]),
        OpCode.nullConstant: Definition(name: "OpNull"),
        OpCode.setGlobal: Definition(name: "OpSetGlobal", operandWidths: [2]),
        OpCode.getGlobal: Definition(name: "OpGetGlobal", operandWidths: [2]),
        OpCode.setLocal: Definition(name: "OpSetLocal", operandWidths: [1]),
        OpCode.getLocal: Definition(name: "OpGetLocal", operandWidths: [1]),
        OpCode.array: Definition(name: "OpArray", operandWidths: [2]),
        OpCode.hash: Definition(name: "OpHash", operandWidths: [2]),
        OpCode.index: Definition(name: "OpIndex"),
        OpCode.call: Definition(name: "OpCall", operandWidths: [1]),
        OpCode.returnValue: Definition(name: "OpReturnValue"),
        OpCode.returnNone: Definition(name: "OpReturnNone"),
        OpCode.getBuiltin: Definition(name: "OpGetBuiltin", operandWidths: [1]),
        OpCode.getFree: Definition(name: "OpGetFree", operandWidths: [1]),
        OpCode.closure: Definition(name: "OpClosure", operandWidths: [2, 1]),
        OpCode.currentClosure: Definition(name: "OpCurrentClosure")
    ]

    static func make(op: OpCode, operands: [Int] = []) -> BinaryInstructions {
        make(op: op.rawValue, operands: operands)
    }

    static func make(op: UInt8, operands: [Int] = []) -> BinaryInstructions {
        let opCode = OpCode(rawValue: op)!
        let def = definitions[opCode]!

        var instructionLen = 1
        for w in def.operandWidths {
            instructionLen += w
        }

        var instruction = BinaryInstructions(count: instructionLen)
        instruction[0] = op

        var offset = 1
        for i in 0..<operands.count {
            let w = def.operandWidths[i]
            let operand = operands[i]

            if w == 1 {
                instruction[offset] = UInt8(operand)
            } else if w == 2 {
                instruction[offset] = UInt8(operand >> 8)
                instruction[offset + 1] = UInt8(operand % 256)
            }
            offset += w
        }

        return instruction
    }

    static func readOperands(definition def: Definition, instruction ins: BinaryInstructions) -> ([Int], Int) {
        var operands = Array(repeating: 0, count: def.operandWidths.count)
        var offset = ins.startIndex
        var totalLength = 0

        for i in 0..<def.operandWidths.count {
            let width = def.operandWidths[i]
            switch width {
            case 1:
                operands[i] = Int(readUInt8(ins: ins[offset...offset]))
            case 2:
                operands[i] = Int(readUInt16(ins: ins[offset...offset + 1]))
            default: break
            }

            offset += width
            totalLength += width
        }

        return (operands, totalLength)
    }

    static func readUInt8(ins: BinaryInstructions) -> UInt8 {
        return UInt8(ins[ins.startIndex])
    }

    static func readUInt16(ins: BinaryInstructions) -> UInt16 {
        var result: UInt16 = 0
        result = UInt16(ins[ins.startIndex]) << 8
        result |= UInt16(ins[ins.startIndex + 1])
        return result
    }

    static func readableInstructionString(definition: Code.Definition, operands: [Int]) -> String? {
        guard definition.operandWidths.count == operands.count else {
            print("Error - operand \(operands) len did not match defined \(definition.operandWidths)")
            return nil
        }

        switch operands.count {
        case 0:
            return definition.name
        case 1:
            return "\(definition.name) \(operands[0])"
        case 2:
            return "\(definition.name) \(operands[0]) \(operands[1])"
        default:
            print("Error - operand count \(operands.count) invaild")
            return nil
        }
    }
}
