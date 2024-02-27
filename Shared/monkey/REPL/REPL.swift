//
//  REPL.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/01/14.
//

import Foundation

class REPL {
    var globalVariables: [Object] = Array(repeating: ObjectImp.Integer(value: 0), count: VM.globalVariableNumber)
    var constants = [Object]()
    var symbolTable = SymbalTable()
    var vm: VM?

    static func createProgram(input: String) -> Program {
        let lexer = Lexer(input)
        let parser = Parser(lexer)
        let program = parser.parseProgram()

        print("\n==== Parse ====")
        for state in program.statements {
            print("\(state.string())")
        }

        if parser.errors.count > 0 {
            print("Parsed error:")
            for err in parser.errors {
                print("\n\(err)")
            }
        }
        return program
    }

    func startCompiling() -> ((String) -> Void) {
        for index in 0..<Builtins.count {
            let builtin = Builtins[index]
            symbolTable.defineBuiltin(index: index, name: builtin.name)
        }

        let executor = { [weak self] (input: String) -> () in
            guard let self else { return }
            let program = REPL.createProgram(input: input)
            let compiler = Compiler.initWithState(constants: &self.constants, symbolTable: &self.symbolTable)
            do {
                try compiler.compiler(node: program)
            } catch {
                print("compiler error:\n\(error)")
                return
            }

            let byteCode = compiler.byteCode()
            do {
                if self.vm == nil {
                    self.vm = VM.new(byteCode: byteCode, globalsVariables: &self.globalVariables)
                    try self.vm?.run()
                } else {
                    try self.vm?.continueRun(byteCode: byteCode)
                }
                print("result:\n\(self.vm?.lastPoped.inspect() ?? "")")
            } catch {
                print("vm error: \(error)")
                return
            }
        }

        return executor
    }
}
