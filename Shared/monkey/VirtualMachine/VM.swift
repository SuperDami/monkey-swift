//
//  vm.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/01/11.
//

import Foundation
class VM {
    static let globalVariableNumber = 65536
    static let stackSize = 2048
    static let maxFrame = 1024

    private let ConstantTureObj = ObjectImp.Boolean(value: true)
    private let ConstantFalseObj = ObjectImp.Boolean(value: false)
    private let ConstantNullObj = ObjectImp.Null()

    enum error: Error {
        case unknow
        case overStackSize
        case notExpectedType(expect: String, actual: String)
        case popObjectFailed
        case unusableHashKey
        case notSupportForIndex
        case expectingFunction
        case callFunctionArgumentNumIncorrect
    }

    private var constants: [Object]
    private var stackTopPos: Int
    private var stack: [Object] = Array(repeating: ObjectImp.Integer(value: 0), count: VM.stackSize)

    private var globals: [Object] = Array(repeating: ObjectImp.Integer(value: 0), count: VM.globalVariableNumber)

    private var frames: [Frame]
    private var framesIndex: Int
    private var currentFrame: Frame { frames[framesIndex - 1] }

    static func new(byteCode: ByteCode, globalsVariables: inout [Object]) -> VM {


        let defaultFrame = Frame(closure: ObjectImp.Closure(fn: ObjectImp.CompiledFunction(instructions: BinaryInstructions(), numLocals: 0, numParameters: 0)), basePointer: 0)
        let mainFN = ObjectImp.CompiledFunction(instructions: byteCode.instructions,
                                                numLocals: 0,
                                                numParameters: 0)
        var frames = Array<Frame>(repeating: defaultFrame, count: maxFrame)
        frames[0] = Frame(closure: ObjectImp.Closure(fn: mainFN), basePointer: 0)        
        return VM(byteCode: byteCode, globalsVariables: &globalsVariables, frames: frames, frameIndex: 1)
    }

    init(byteCode: ByteCode,
         globalsVariables: inout [Object],
         frames: [Frame],
         frameIndex: Int) {
        self.constants = byteCode.constants
        self.stackTopPos = 0
        self.frames = frames
        self.framesIndex = frameIndex
        self.globals = globalsVariables
    }

    func continueRun(byteCode: ByteCode) throws {
        self.constants = byteCode.constants
        var newIns = currentFrame.instructions
        newIns.append(byteCode.instructions)

        let newFN = ObjectImp.CompiledFunction(instructions: newIns,
                                               numLocals: currentFrame.closure.fn.numLocals,
                                               numParameters: currentFrame.closure.fn.numParameters)

        let newFrame = Frame(closure: ObjectImp.Closure(fn: newFN), basePointer: currentFrame.basePointer)
        newFrame.ip = currentFrame.ip
        frames[framesIndex - 1] = newFrame

        try run()
    }

    func run() throws {
        while currentFrame.ip < currentFrame.instructions.count - 1 {
            currentFrame.ip += 1

            let index = currentFrame.ip
            let opCode = OpCode(rawValue: currentFrame.instructions[index])!
            switch opCode {
            case .constant:
                let constantIndex = Code.readUInt16(ins: currentFrame.instructions[(index + 1)...(index + 2)])
                currentFrame.ip += 2
                try pushToStack(constants[Int(constantIndex)])
            case .add, .sub, .mutiple, .divide:
                try executeBinaryOperation(op: opCode)
            case .pop:
                stackPop()
            case .equal, .notEqual, .greaterThan:
                try executeComparingOperation(op: opCode)
            case .trueConstant:
                try pushToStack(ConstantTureObj)
            case .falseConstant:
                try pushToStack(ConstantFalseObj)
            case .bang:
                let booleanValue = try popObjectForBooleanValue()
                if booleanValue {
                    try pushToStack(ConstantFalseObj)
                } else {
                    try pushToStack(ConstantTureObj)
                }
            case .minus:
                let integer = try popStackObject(requiredType: ObjectImp.Integer.self)
                try pushToStack(ObjectImp.Integer(value: -integer.value))
            case .jump, .jumpNotTrurhy:
                let jumpPos = Code.readUInt16(ins: currentFrame.instructions[(index + 1)...(index + 2)])
                if opCode == .jump {
                    currentFrame.ip = Int(jumpPos) - 1 // Jump to after alternative
                } else {
                    let conditionIsTrue = try popObjectForBooleanValue()
                    if conditionIsTrue {
                        currentFrame.ip += 2 // Continue to consequence
                    } else {
                        currentFrame.ip = Int(jumpPos) - 1 // Jump to alternative
                    }
                }
            case .nullConstant:
                try pushToStack(ConstantNullObj)
            case .setGlobal, .getGlobal:
                let symbolIndex = Int(Code.readUInt16(ins: currentFrame.instructions[(index + 1)...(index + 2)]))
                currentFrame.ip += 2

                if opCode == .setGlobal {
                    globals[symbolIndex] = stackPop()
                } else {
                    try pushToStack(globals[symbolIndex])
                }
            case .setLocal:
                let localIndex = Int(Code.readUInt8(ins: currentFrame.instructions[(index + 1)...(index + 1)]))
                currentFrame.ip += 1
                stack[currentFrame.basePointer + localIndex] = stackPop()
            case .getLocal:
                let localIndex = Int(Code.readUInt8(ins: currentFrame.instructions[(index + 1)...(index + 1)]))
                currentFrame.ip += 1
                try pushToStack(stack[currentFrame.basePointer + localIndex])
            case .getBuiltin:
                let builtinIndex = Int(Code.readUInt8(ins: currentFrame.instructions[(index + 1)...(index + 1)]))
                currentFrame.ip += 1
                let define = Builtins[builtinIndex]
                try pushToStack(define.builtin)
            case .getFree:
                let freeIndex = Int(Code.readUInt8(ins: currentFrame.instructions[(index + 1)...(index + 1)]))
                currentFrame.ip += 1
                let freeArgument = currentFrame.closure.free[freeIndex]
                try pushToStack(freeArgument)
            case .array:
                let elementNumber = Int(Code.readUInt16(ins: currentFrame.instructions[(index + 1)...(index + 2)]))
                currentFrame.ip += 2

                let array = buildArrayFromStack(startIdx: stackTopPos - elementNumber, count: elementNumber)
                stackTopPos -= elementNumber
                try pushToStack(array)
            case .hash:
                let elements = Int(Code.readUInt16(ins: currentFrame.instructions[(index + 1)...(index + 2)]))
                currentFrame.ip += 2

                let hash = try buildHashFromStack(startId: stackTopPos - elements, endIndex: stackTopPos - 1)
                stackTopPos -= elements
                try pushToStack(hash)
            case .index:
                let index = stackPop()
                let left = stackPop()
                try executeIndexExpression(left: left, index: index)
            case .call:
                let fnArgumentNumber = Int(Code.readUInt8(ins: currentFrame.instructions[(index + 1)...(index + 1)]))
                currentFrame.ip += 1
                try executeCallFunction(fnArgumentNumber: fnArgumentNumber)
            case .returnValue, .returnNone:
                var returnValue: Object = ConstantNullObj
                if opCode == .returnValue {
                    returnValue = stackPop()
                }
                let frame = popFrame()
                stackTopPos = frame.basePointer - 1 // -1 is for pop the compiled function
                try pushToStack(returnValue)
            case .closure:
                let fnIndex = Int(Code.readUInt16(ins: currentFrame.instructions[(index + 1)...(index + 2)]))
                currentFrame.ip += 2
                let freeNumber = Int(Code.readUInt8(ins: currentFrame.instructions[(currentFrame.ip + 1)...(currentFrame.ip + 1)]))
                currentFrame.ip += 1
                try pushClosure(constantIndex: fnIndex, freeNumber: freeNumber)
            case .currentClosure:
                let currentClosure = currentFrame.closure
                try pushToStack(currentClosure)
            }
        }

    }

    var stackTop: Object? {
        return stackTopPos > 0 ? stack[stackTopPos - 1] : nil
    }

    var lastPoped: Object {
        return stack[stackTopPos]
    }
}

//Internal
fileprivate extension VM {
    func pushToStack(_ object: Object) throws {
        if stackTopPos >= stack.count {
            throw error.overStackSize
        }

        stack[stackTopPos] = object
        stackTopPos += 1
    }

    func executeBinaryOperation(op: OpCode) throws {
        if let objects = try? popStackPairObjects(requiredType: ObjectImp.Integer.self) {
            var result: Int64 = 0
            switch op {
            case .add:
                result = objects.left.value + objects.right.value
            case .sub:
                result = objects.left.value - objects.right.value
            case .mutiple:
                result = objects.left.value * objects.right.value
            case .divide:
                result = objects.left.value / objects.right.value
            default:
                throw error.unknow
            }
            try pushToStack(ObjectImp.Integer(value: result))
        } else if let objects = try? popStackPairObjects(requiredType: ObjectImp.String.self) {
            switch op {
            case .add:
                let newString = ObjectImp.String(value: objects.left.value + objects.right.value)
                try pushToStack(newString)
            default:
                throw error.unknow
            }
        } else {
            throw error.notExpectedType(expect: "A pair of \(ObjectImp.Integer.self) or \(ObjectImp.String.self)", actual: "\(stack[stackTopPos - 1].type.self) and \(stack[stackTopPos - 2].type.self)")
        }
    }

    func executeComparingOperation(op: OpCode) throws {
        var result = false
        if let integers = try? popStackPairObjects(requiredType: ObjectImp.Integer.self) {
            switch op {
            case .equal:
                result = integers.left.value == integers.right.value
            case .notEqual:
                result = integers.left.value != integers.right.value
            case .greaterThan:
                result = integers.left.value > integers.right.value
            default:
                throw error.unknow
            }
        } else if let booleans = try? popStackPairObjects(requiredType: ObjectImp.Boolean.self) {
            switch op {
            case .equal:
                result = booleans.left.value == booleans.right.value
            case .notEqual:
                result = booleans.left.value != booleans.right.value
            default:
                throw error.unknow
            }
        } else {
            throw error.notExpectedType(expect: "A pair of \(ObjectImp.Integer.self) or \(ObjectImp.Boolean.self)", actual: "\(stackTop?.type.rawValue ?? "")")
        }

        if result {
            try pushToStack(ConstantTureObj)
        } else {
            try pushToStack(ConstantFalseObj)
        }
    }

    @discardableResult
    func stackPop() -> Object {
        let result = stack[stackTopPos - 1]
        stackTopPos -= 1
        return result
    }

    func popStackPairObjects<T: Object>(requiredType: T.Type) throws -> (left: T, right: T) {
        guard stackTopPos >= 2 else {
            throw error.popObjectFailed
        }

        guard let right = stack[stackTopPos - 1] as? T,
           let left = stack[stackTopPos - 2] as? T else {
            throw error.notExpectedType(expect: "\(T.self)", actual: "\(stack[stackTopPos - 1].self) and \(stack[stackTopPos - 2].self)")
        }

        stackPop()
        stackPop()
        return (left, right)
    }

    func popStackObject<T: Object>(requiredType: T.Type) throws -> T {
        guard stackTopPos >= 1 else {
            throw error.popObjectFailed
        }

        guard let result = stack[stackTopPos - 1] as? T else {
            throw error.notExpectedType(expect: "\(T.self)", actual: "\(stack[stackTopPos - 1].self)")
        }

        stackPop()
        return result
    }

    func popObjectForBooleanValue() throws -> Bool {
        if let boolean = try? popStackObject(requiredType: ObjectImp.Boolean.self) {
            if boolean === ConstantTureObj {
                return true
            }
            return false
        } else if let _ = try? popStackObject(requiredType: ObjectImp.Null.self) {
            return false
        }

        throw error.notExpectedType(expect: "\(ObjectImp.Boolean.self) or \(ObjectImp.Null.self)", actual: "\(stackTop?.type.rawValue ?? "")")
    }

    func buildArrayFromStack(startIdx: Int, count: Int) -> ObjectImp.Array {
        let elements = Array(stack[startIdx..<startIdx + count])
        return ObjectImp.Array(elements: elements)
    }

    func buildHashFromStack(startId: Int, endIndex: Int) throws -> ObjectImp.Hash {
        typealias HashPair = ObjectImp.Hash.HashPair
        var hash = [Int: HashPair]()
        var index = startId
        while index <= endIndex {
            let key = stack[index]
            let value = stack[index + 1]

            guard let hashable = key as? (any HashObject) else {
                throw error.unusableHashKey
            }

            hash[hashable.hashValue] = ObjectImp.Hash.HashPair(key: hashable, value: value)
            index += 2
        }

        return ObjectImp.Hash(map: hash)
    }

    func executeIndexExpression(left: Object, index: Object) throws {
        if left.type == .ArrayObj && index.type == .IntegerObj {
            let array = left as! ObjectImp.Array
            let integer = index as! ObjectImp.Integer

            if integer.value < 0 || integer.value >= array.elements.count {
                try pushToStack(ConstantNullObj)
            } else {
                try pushToStack(array.elements[Int(integer.value)])
            }
        } else if left.type == .HashObj, let hashable = index as? any Hashable {
            let hash = left as! ObjectImp.Hash
            try pushToStack(hash.map[hashable.hashValue]?.value ?? ConstantNullObj)
        } else {
            throw error.notSupportForIndex
        }
    }

    func executeCallFunction(fnArgumentNumber: Int) throws {
        let callee = stack[stackTopPos - fnArgumentNumber - 1]
        switch callee {
        case let closure as ObjectImp.Closure:
            guard closure.fn.numParameters == fnArgumentNumber else {
                throw error.callFunctionArgumentNumIncorrect
            }
            let newFrame = Frame(closure: closure, basePointer: stackTopPos - fnArgumentNumber)
            pushFrame(newFrame)
            stackTopPos = stackTopPos + closure.fn.numLocals
        case let builtinFunc as ObjectImp.Builtin:
            let arguments = Array(stack[stackTopPos - fnArgumentNumber..<stackTopPos])
            let result = try builtinFunc.fn(arguments)
            stackTopPos = stackTopPos - fnArgumentNumber - 1 // Will replace the builtin function postition
            try pushToStack(result)
        default:
            throw error.expectingFunction
        }
    }

    func pushClosure(constantIndex: Int, freeNumber: Int) throws {
        if let fn = constants[constantIndex] as? ObjectImp.CompiledFunction {
            var frees = Array<Object?>(repeating: nil, count: freeNumber)
            for i in 0..<freeNumber {
                frees[i] = stack[stackTopPos - freeNumber + i]
            }
            stackTopPos = stackTopPos - freeNumber

            let closure = ObjectImp.Closure(fn: fn, free: frees as! [Object])
            try pushToStack(closure)
        } else {
            throw error.expectingFunction
        }
    }
}

// Frame Control
fileprivate extension VM {
    func pushFrame(_ frame: Frame) {
        frames[framesIndex] = frame
        framesIndex += 1
    }

    @discardableResult
    func popFrame() -> Frame {
        framesIndex -= 1
        return frames[framesIndex]
    }
}
