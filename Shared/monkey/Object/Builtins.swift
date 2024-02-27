//
//  Builtins.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/04/04.
//

import Foundation

enum BuiltinFuncName: String {
    case len
    case first
    case last
    case rest
    case push
    case puts
}

private enum error: Error {
    case argumentNumberNotExpected(expect: Int, acture: Int)
    case argumentTypeNotExpected(expect: String, acture: String)
}

let Builtins: [(name: String, builtin: ObjectImp.Builtin)] = [
    (BuiltinFuncName.len.rawValue,
     ObjectImp.Builtin(fn: { args in
         guard args.count == 1 else { throw error.argumentNumberNotExpected(expect: 1, acture: args.count) }
         switch args[0] {
         case let array as ObjectImp.Array:
             return ObjectImp.Integer(value: Int64(array.elements.count))
         case let string as ObjectImp.String:
             return ObjectImp.Integer(value: Int64(string.value.count))
         default:
             throw error.argumentTypeNotExpected(expect: "\(ObjectImp.Array.self) or \(ObjectImp.String.self)", acture: "\(args[0].type)")
         }
     })),
]

func getBuiltin(with name: String) -> ObjectImp.Builtin? {
    return Builtins.first { $0.name == name }.map { $0.builtin }
}
