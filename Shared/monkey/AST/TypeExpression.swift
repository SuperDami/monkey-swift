//
//  TypeExpression.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/24.
//

import Foundation

class BooleanLiteral: Expression {
    let token: Token
    let value: Bool
    
    init(_ t: Token, _ v: Bool) {
        self.token = t
        self.value = v
    }
    
    func string() -> String {
        return token.literal
    }
    
    func experssionNode() {}
}

class IntegerLiteral: Expression {
    let token: Token
    let value: Int

    init(_ t: Token, _ v: Int) {
        self.token = t
        self.value = v
    }
    
    func string() -> String {
        return token.literal
    }
    
    func experssionNode() {}
}

class StringLiteral: Expression {
    let token: Token
    var value: String { get {
        return token.literal
    }}
    
    init(_ t: Token) {
        self.token = t
    }
    
    func string() -> String {
        return value
    }
    
    func experssionNode() {}
}

class ArrayLiteral: Expression {
    let token = Token(.LeftBracket)
    let elements: [Expression]

    init(elements: [Expression]) {
        self.elements = elements
    }

    func string() -> String {
        var str = ""
        str += TokenType.LeftBracket.rawValue
        for i in 0..<elements.count {
            str += elements[i].string()
            if i < elements.count - 1 {
                str += ", "
            }
        }
        str += TokenType.RightBracket.rawValue
        return str
    }

    func experssionNode() {}
}

class HashLiteral: Expression {
    let token = Token(.LeftBrace)
    var pairs: [(key: Expression, value: Expression)]

    init(pairs: [(key: Expression, value: Expression)]) {
        self.pairs = pairs
    }

    func string() -> String {
        var str = "{"
        if pairs.count > 0 {
            str += "\n"
            for i in 0..<pairs.count {
                let keyStr = pairs[i].key.string()
                let valueStr = pairs[i].value.string()
                str += keyStr + ": " + valueStr + "\n"
            }
        }
        str += "}"
        return str
    }

    func experssionNode() {}
}
