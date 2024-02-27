//
//  ObjectImp.swift
//  monkey-swift
//
//  Created by zhejun chen on 2022/12/31.
//

import Foundation
typealias NativeString = String
typealias NativeArray = Array

struct ObjectImp {
    class Integer: HashObject {
        let value: Int64
        let type = ObjectType.IntegerObj

        init(value: Int64) {
            self.value = value
        }

        func inspect() -> NativeString {
            return "\(value)"
        }

        static func == (lhs: ObjectImp.Integer, rhs: ObjectImp.Integer) -> Bool {
            return lhs.value == rhs.value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(value)
        }
    }

    class Boolean: HashObject {
        let value: Bool
        let type = ObjectType.BooleanObj

        init(value: Bool) {
            self.value = value
        }

        func inspect() -> NativeString {
            return "\(value)"
        }

        static func == (lhs: ObjectImp.Boolean, rhs: ObjectImp.Boolean) -> Bool {
            return lhs.value == rhs.value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(value)
        }
    }

    class Null: Object {
        let type = ObjectType.NullObj
        func inspect() -> NativeString {
            return "null"
        }
    }

    class String: HashObject {
        let value: NativeString
        let type = ObjectType.StringObj
        func inspect() -> NativeString {
            return value
        }

        init(value: NativeString) {
            self.value = value
        }

        static func == (lhs: ObjectImp.String, rhs: ObjectImp.String) -> Bool {
            return lhs.value == rhs.value
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(value)
        }
    }

    class Array: Object {
        let elements: [Object]
        let type = ObjectType.ArrayObj
        func inspect() -> NativeString {
            var str = ""
            for idx in 0..<elements.count {
                if idx > 0 {
                    str += ", "
                }
                str += elements[idx].inspect()
            }

            return str
        }

        init(elements: [Object]) {
            self.elements = elements
        }
    }

    class Hash: Object {
        struct HashPair {
            let key: any HashObject
            let value: Object
        }

        let map: [Int: HashPair]
        let type = ObjectType.HashObj
        func inspect() -> NativeString {
            var str = "{"
            for (idx, value) in map {
                str += "(\(idx))\(value.key): \(value.value)\n"
            }
            str += "}"
            return str
        }

        init(map: [Int: HashPair]) {
            self.map = map
        }
    }

    class CompiledFunction: Object {
        let instructions: BinaryInstructions
        let numLocals: Int
        let numParameters: Int
        let type = ObjectType.CompiledFunc
        func inspect() -> NativeString {
            return "CompiledFunction"
        }

        init(instructions: BinaryInstructions, numLocals: Int, numParameters: Int) {
            self.instructions = instructions
            self.numLocals = numLocals
            self.numParameters = numParameters
        }
    }

    class Builtin: Object {
        typealias BuiltinFunction = ([Object]) throws -> Object
        let fn: BuiltinFunction
        let type = ObjectType.BuiltinObj
        func inspect() -> NativeString {
            return ""
        }

        init(fn: @escaping BuiltinFunction) {
            self.fn = fn
        }
    }

    class Closure: Object {
        let fn: CompiledFunction
        let free: [Object]
        let type = ObjectType.BuiltinObj

        func inspect() -> NativeString {
            return "Closure[\(self)]"
        }

        init(fn: CompiledFunction, free: [Object] = []) {
            self.fn = fn
            self.free = free
        }
    }
}
