//
//  Expression.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/23.
//

import Foundation

protocol Expression: Node {
    func experssionNode()
}

class IdentifierExp: Expression {
    let token: Token
    let value: String
    
    init(_ token: Token) {
        self.token = token
        self.value = token.literal
    }
                
    func string() -> String {
        return value
    }
    
    func experssionNode() {}
}

class PrefixExpression: Expression {
    let token: Token
    let op: String
    let right: Expression
    
    init(_ t: Token, _ exp: Expression) {
        self.token = t
        self.op = t.literal
        self.right = exp
    }
    
    func string() -> String {
        return TokenType.LeftParen.rawValue + op + right.string() + TokenType.RightParen.rawValue
    }
    
    func experssionNode() {}
}

class InfixExpression: Expression {
    let token: Token
    let left: Expression
    let op: String
    let right: Expression
    
    init(_ t: Token, _ lExp: Expression, _ rExp: Expression) {
        self.token = t
        self.left = lExp
        self.op = token.literal
        self.right = rExp
    }
    
    func string() -> String {
        return TokenType.LeftParen.rawValue + left.string() + " " + op + " " + right.string() + TokenType.RightParen.rawValue
    }
    
    func experssionNode() {}
}

class IfExpression: Expression {
    let token = Token(.If)
    let condition: Expression
    let consequence: BlockStatement
    let alternative: BlockStatement?

    init(condition: Expression, consequence: BlockStatement, alternative: BlockStatement?) {
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }

    func string() -> String {
        var str = ""
        str += token.literal + " " + condition.string() + "\n"
        str += consequence.string()

        if let alternative = alternative {
            str += "else \n"
            str += alternative.string()
        }
        return str
    }

    func experssionNode() {}
}

class CallExpression: Expression {
    let token = Token(.LeftParen)
    let function: Expression       // Identifer or functionLiteral
    let arguements: [Expression]

    init(function: Expression, arguements: [Expression]) {
        self.function = function
        self.arguements = arguements
    }

    func string() -> String {
        var args = ""
        for i in 0..<arguements.count {
            args += arguements[i].string().removeNewLine()
            if i < arguements.count - 1 {
                args += ", "
            }
        }

        return function.string() + TokenType.LeftParen.rawValue + args + TokenType.RightParen.rawValue
    }

    func experssionNode() {}
}

class FunctionLiteral: Expression {
    let token = Token(.Function)
    let parameters: [IdentifierExp]
    let body: BlockStatement
    var name: String?

    init(parameters: [IdentifierExp], body: BlockStatement) {
        self.parameters = parameters
        self.body = body
    }

    func string() -> String {
        var str = ""
        str += tokenLiteral()
        if let name {
            str += "<\(name)> "
        }
        str += TokenType.LeftParen.rawValue + " "

        str += parameters.flatMap({ $0.string() + ", " })
        str += TokenType.RightParen.rawValue + "\n"
        str += body.string()

        return str
    }

    func experssionNode() {}
}

class IndexExpression: Expression {
    let token = Token(.LeftBracket)
    var left: Expression
    let index: Expression

    init(left: Expression, index: Expression) {
        self.left = left
        self.index = index
    }

    func string() -> String {
        var str = ""
        str += TokenType.LeftParen.rawValue // (
        + left.string() + TokenType.LeftBracket.rawValue + index.string() + TokenType.RightBracket.rawValue // Container[Index]
        + TokenType.RightParen.rawValue //)
        return str
    }

    func experssionNode() {}
}
