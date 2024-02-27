//
//  Compiler.swift
//  monkey-swift
//
//  Created by zhejun chen on 2022/12/27.
//

import Foundation

struct ByteCode {
    let instructions: BinaryInstructions
    var constants: [Object]
}

struct EmittedInstruction {
    let opCode: OpCode
    let position: Int
}

struct CompilationScope {
    var instructions = BinaryInstructions()
    var lastInstruction: EmittedInstruction? = nil
    var previousInstruction: EmittedInstruction? = nil
}

class Compiler {
    enum error: Error {
        case unknowOperator(String)
        case unknowAstNode
        case invalidHash
    }

    fileprivate struct Constant {
         static let holdplaceOperand = 9999
    }

    var currentInstructions: BinaryInstructions {
        return scopes[scopeIndex].instructions
    }
    private(set) var constants = [Object]()
    private(set) var symbolTable = SymbalTable()
    
    private(set) var scopes = [CompilationScope()]
    private(set) var scopeIndex = 0

    static func initWithState(constants: inout [Object],
                            symbolTable: inout SymbalTable) -> Compiler {
        let compiler = Compiler()
        compiler.constants = constants
        compiler.symbolTable = symbolTable
        return compiler
    }

    func compiler(node: Node) throws {
        switch node {
        case let program as Program:
            for statment in program.statements {
                try compiler(node: statment)
            }
        case let unwrappedNode as ExpressionStatement:
            try compiler(node: unwrappedNode.expression)
            emit(opCode: .pop)
        case let unwrappedNode as InfixExpression:
            try compilerInfixExpression(unwrappedNode)
        case let unwrappedNode as PrefixExpression:
            try compilerPrefixExpression(unwrappedNode)
        case let integerNode as IntegerLiteral:
            let integer = ObjectImp.Integer(value: Int64(integerNode.value))
            emit(opCode: .constant, operands: addConstant(integer))
        case let stringNode as StringLiteral:
            let string = ObjectImp.String(value: stringNode.value)
            emit(opCode: .constant, operands: addConstant(string))
        case let booleanNode as BooleanLiteral:
            if booleanNode.value {
                emit(opCode: .trueConstant)
            } else {
                emit(opCode: .falseConstant)
            }
        case let ifExpression as IfExpression:
            try compiler(node: ifExpression.condition)
            let jumpToAlternativeOp = emit(opCode: .jumpNotTrurhy, operands: Constant.holdplaceOperand)
            try compiler(node: ifExpression.consequence)

            removeLastPopInstruction()

            let jumpToAfterAlternativeOp = emit(opCode: .jump, operands: Constant.holdplaceOperand)
            let afterConsequencePos = currentInstructions.count
            changeOperand(opPosition: jumpToAlternativeOp, operand: afterConsequencePos)

            if ifExpression.alternative == nil {
                // if (condition) {
                //     consequence
                // }
                // `afterConsequencePos`

                emit(opCode: .nullConstant)
            } else {
                // if (condition) {
                //     consequence
                // } else {
                // `afterConsequencePos`
                //     alternative
                // }
                // `afterAlternativePos`

                try compiler(node: ifExpression.alternative!)
                removeLastPopInstruction()
            }

            let afterAlternativePos = currentInstructions.count
            changeOperand(opPosition: jumpToAfterAlternativeOp, operand: afterAlternativePos)
        case let letStatement as LetStatement:
            let symbol = try symbolTable.define(name: letStatement.name.value)
            try compiler(node: letStatement.value)
            let opCode = symbol.scope == .global ? OpCode.setGlobal : OpCode.setLocal
            emit(opCode: opCode, operands: symbol.index)
        case let identifierExp as IdentifierExp:
            let symbol = try symbolTable.resolve(name: identifierExp.value)
            emitLoadSymbol(symbol: symbol)
        case let arrayLiteral as ArrayLiteral:
            for element in arrayLiteral.elements {
                try compiler(node: element)
            }
            emit(opCode: .array, operands: arrayLiteral.elements.count)
        case let hashLiteral as HashLiteral:

            let sortedPairs = hashLiteral.pairs.sorted(by: {
                $0.key.string() < $1.key.string()
            })

            for i in 0..<sortedPairs.count {
                try compiler(node: sortedPairs[i].key)
                try compiler(node: sortedPairs[i].value)
            }
            emit(opCode: .hash, operands: hashLiteral.pairs.count * 2)
        case let indexExp as IndexExpression:
            try compiler(node: indexExp.left)
            try compiler(node: indexExp.index)
            emit(opCode: .index)
        case let functionLiteral as FunctionLiteral:
            enterScope()

//            if let fnName = functionLiteral.name {
//                symbolTable.defineFunctionName(name: fnName)
//            }

            for parameter in functionLiteral.parameters {
                try symbolTable.define(name: parameter.value)
            }
            try compiler(node: functionLiteral.body)
            makeFunctionEndWithReturn()

            let freeSymbols = symbolTable.freeSymbols
            let numLocals = symbolTable.numDefinitions
            let funcScopeInstructions = leaveScope()

            for s in freeSymbols {
                emitLoadSymbol(symbol: s)
            }

            let compiledFunc = ObjectImp.CompiledFunction(instructions: funcScopeInstructions,
                                                          numLocals: numLocals,
                                                          numParameters: functionLiteral.parameters.count)
            let fnIndex = addConstant(compiledFunc)
            emit(opCode: .closure, operands: fnIndex, freeSymbols.count)
        case let returnStatement as ReturnStatement:
            try compiler(node: returnStatement.returnValue)
            emit(opCode: .returnValue)
        case let callExp as CallExpression:
            try compiler(node: callExp.function)
            for arg in callExp.arguements {
                try compiler(node: arg)
            }
            emit(opCode: .call, operands: callExp.arguements.count)
        case let blockExt as BlockStatement:
            for statement in blockExt.statements {
                try compiler(node: statement)
            }
        default:
            throw error.unknowAstNode
        }
    }

    func byteCode() -> ByteCode {
        return ByteCode(instructions: currentInstructions, constants: constants)
    }
}

internal extension Compiler {
    func emitLoadSymbol(symbol: Symbol) {
        switch symbol.scope {
        case .global:
            emit(opCode: .getGlobal, operands: symbol.index)
        case .local:
            emit(opCode: .getLocal, operands: symbol.index)
        case .builtin:
            emit(opCode: .getBuiltin, operands: symbol.index)
        case .free:
            emit(opCode: .getFree, operands: symbol.index)
        case .function:
            emit(opCode: .currentClosure)
        }
    }

    func compilerInfixExpression(_ exp: InfixExpression) throws {
        if exp.op == "<" {
            try compiler(node: exp.right)
            try compiler(node: exp.left)
        } else {
            try compiler(node: exp.left)
            try compiler(node: exp.right)
        }

        switch exp.op {
        case "+": emit(opCode: OpCode.add)
        case "-": emit(opCode: OpCode.sub)
        case "*": emit(opCode: OpCode.mutiple)
        case "/": emit(opCode: OpCode.divide)
        case ">", "<": emit(opCode: OpCode.greaterThan)
        case "==": emit(opCode: OpCode.equal)
        case "!=": emit(opCode: OpCode.notEqual)
        default: throw error.unknowOperator(exp.op)
        }
    }

    func compilerPrefixExpression(_ exp: PrefixExpression) throws {
        try compiler(node: exp.right)
        switch exp.op {
        case "!": emit(opCode: OpCode.bang)
        case "-": emit(opCode: OpCode.minus)
        default: throw error.unknowOperator(exp.op)
        }
    }

    func addConstant(_ obj: Object) -> Int {
        constants.append(obj)
        return constants.count - 1
    }

    func changeOperand(opPosition: Int, operand: Int) {
        let binaryIns = Code.make(op: currentInstructions[opPosition], operands: [operand])
        for index in 0..<binaryIns.count {
            scopes[scopeIndex].instructions[opPosition + index] = binaryIns[index]
        }
    }

    @discardableResult
    func removeLastPopInstruction() -> Bool {
        guard let lastOp = scopes[scopeIndex].lastInstruction, lastOp.opCode == .pop else { return false }
        let slicedInstructions = currentInstructions[0..<lastOp.position]

        scopes[scopeIndex].lastInstruction = scopes[scopeIndex].previousInstruction
        scopes[scopeIndex].instructions = slicedInstructions
        return true
    }

    func makeFunctionEndWithReturn() {
        if let lastOp = scopes[scopeIndex].lastInstruction, lastOp.opCode == .pop {
            let lastPosition = scopes[scopeIndex].lastInstruction!.position
            let binaryIns = Code.make(op: OpCode.returnValue)
            for index in 0..<binaryIns.count {
                scopes[scopeIndex].instructions[lastPosition + index] = binaryIns[index]
            }
            scopes[scopeIndex].lastInstruction = EmittedInstruction(opCode: .returnValue, position: lastPosition)
        }

        if scopes[scopeIndex].lastInstruction?.opCode != .returnValue {
            emit(opCode: .returnNone)
        }
    }
}

// Scope Control
internal extension Compiler {
    @discardableResult
    func emit(opCode: OpCode, operands: Int...) -> Int {
        let instruction = Code.make(op: opCode, operands: operands as [Int])
        let pos = currentInstructions.count

        let newPrevious = scopes[scopeIndex].lastInstruction
        scopes[scopeIndex].lastInstruction = EmittedInstruction(opCode: opCode, position: pos)
        scopes[scopeIndex].previousInstruction = newPrevious
        scopes[scopeIndex].instructions.append(instruction)
        return pos
    }
    
    func enterScope() {
        let newScope = CompilationScope()
        scopes.append(newScope)
        scopeIndex += 1
        symbolTable = SymbalTable(outer: symbolTable)
    }

    func leaveScope() -> BinaryInstructions {
        let instructions = currentInstructions
        scopes.removeLast()
        scopeIndex -= 1
        
        symbolTable = symbolTable.outer!
        return instructions
    }
}
