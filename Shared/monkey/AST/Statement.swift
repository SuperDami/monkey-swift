//
//  Statement.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/23.
//

import Foundation

protocol Statement: Node {
    func statementNode()
}

class LetStatement: Statement {
    let token: Token
    let name: IdentifierExp
    let value: Expression
    
    init(_ t: Token, _ n: IdentifierExp, _ v: Expression) {
        self.token = t
        self.name = n
        self.value = v
    }
    
    func string() -> String {
        return token.literal + " " + name.string() + " = " + value.string()
    }
    
    func statementNode() {}
}

class ReturnStatement: Statement {
    var token = Token(.Return)
    var returnValue: Expression

    init(returnValue: Expression) {
        self.returnValue = returnValue
    }

    func string() -> String {
        return tokenLiteral() + " " + returnValue.string()
    }

    func statementNode() {}
}

class ExpressionStatement: Statement {
    let token: Token
    let expression: Expression
    
    init(_ t: Token, _ e: Expression) {
        self.token = t
        self.expression = e
    }
    
    func string() -> String {
        return expression.string()
    }
    
    func statementNode() {}
}

class BlockStatement: Statement {
    let token: Token
    let statements: [Statement]

    init(statements: [Statement]) {
        self.token = Token(.LeftBrace)
        self.statements = statements
    }

    func string() -> String {
        var str = ""
        str += TokenType.LeftBrace.rawValue + " \n"
        for statement in statements {
            str += statement.string() + "\n"
        }

        str += TokenType.RightBrace.rawValue
        return str
    }

    func statementNode() {}
}
