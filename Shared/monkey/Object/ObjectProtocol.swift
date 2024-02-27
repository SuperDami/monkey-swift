//
//  Object.swift
//  monkey-swift
//
//  Created by zhejun chen on 2022/12/31.
//

import Foundation

enum ObjectType: String {
    case IntegerObj  = "Integer"
    case BooleanObj  = "Boolean"
    case NullObj     = "Null"
    case StringObj   = "String"
    case ArrayObj    = "Array"
    case HashObj     = "Hash"
    case CompiledFunc = "CompiledFunc"
    case BuiltinObj   = "Builtin"
    case ClosureObj   = "Closure"
}

protocol Object {
    var type: ObjectType { get }
    func inspect() -> String
}

protocol HashObject: Object, Hashable {
    associatedtype T
    var value: T { get }
}
