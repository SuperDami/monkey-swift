//
//  Parser.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/23.
//

import Foundation

enum ParserError: Error {
    case msg (_ msg: String)
}

private enum Precedences: Int {
    case Lowest = 0
    case Equals         // = or !=
    case LessOrGreater  // < or >
    case Sum            // +
    case Product        // *
    case Prefix         // -X or !X
    case Call           // aFunction()
    case Index          // array[index]
    
    static func < (_ left: Precedences, _ right: Precedences) -> Bool {
        return left.rawValue < right.rawValue
    }
    
    static func > (_ left: Precedences, _ right: Precedences) -> Bool {
        return left.rawValue > right.rawValue
    }
    
    static func == (_ left: Precedences, _ right: Precedences) -> Bool {
        return left.rawValue == right.rawValue
    }
}

private let operatorPrecedences = [
    TokenType.Equal: Precedences.Equals,
    TokenType.NotEqual: Precedences.Equals,
    TokenType.GreaterThan: Precedences.LessOrGreater,
    TokenType.LessThan: Precedences.LessOrGreater,
    TokenType.Plus: Precedences.Sum,
    TokenType.Minus: Precedences.Sum,
    TokenType.Asterisk: Precedences.Product,
    TokenType.Slash: Precedences.Product,
    TokenType.LeftParen: Precedences.Call,
    TokenType.LeftBracket: Precedences.Index
]

class Parser {
    enum error: Error {
        case notExpectExpression(expect: String, actual: String)
        case notExpectedToken(expect: String, actual: String)
        case message(String)
    }

    var lexer: Lexer
    var errors = [Error]()
    
    var currentToken: Token?
    var peekToken: Token?
    
    lazy var prefixParserFuncs = {
        var registerMap = [TokenType: () throws -> Expression]()
        registerMap[.Identifier] = parseIdentifierExpression
        registerMap[.Int] = parseIntegerLiteral
        registerMap[.True] = parseBooleanLiteral
        registerMap[.False] = parseBooleanLiteral
        registerMap[.String] = parseStringLiteral
        registerMap[.Bang] = parsePrefixExpression
        registerMap[.Minus] = parsePrefixExpression
        registerMap[.LeftParen] = parseGroupedExpression
        registerMap[.If] = parseIfExpression
        registerMap[.Function] = parseFunctionLiteral
        registerMap[.LeftBracket] = parseArrayLiteral
        registerMap[.LeftBrace] = parseHashLiteral
        return registerMap
    }()

    lazy var infixParserFuncs = {
        var registerMap = [TokenType: (Expression) throws -> Expression]()
        registerMap[.Plus] = parseInfixExpression
        registerMap[.Minus] = parseInfixExpression
        registerMap[.Asterisk] = parseInfixExpression
        registerMap[.Slash] = parseInfixExpression
        registerMap[.Equal] = parseInfixExpression
        registerMap[.NotEqual] = parseInfixExpression
        registerMap[.LessThan] = parseInfixExpression
        registerMap[.GreaterThan] = parseInfixExpression

        registerMap[.LeftParen] = parseCallExpression
        registerMap[.LeftBracket] = parseIndexExpression
        return registerMap
    }()
    
    init(_ lexer: Lexer) {
        self.lexer = lexer
        nextToken()
        nextToken() // Make current token and peek token ready
    }
    
    private func expectToken(_ token: Token?, _ type: TokenType) -> Bool {
        if let token = token, token.type == type {
            return true
        } else {
            return false
        }
    }

    private func expectTokenThrows(_ token: Token?, _ type: TokenType) throws {
        guard let token = token, token.type == type else {
            throw error.notExpectedToken(expect: type.rawValue, actual: token?.type.rawValue ?? "")
        }
    }
    
    private func nextToken(step: Int = 1) {
        var count = step
        while count > 0 {
            currentToken = peekToken
            peekToken = lexer.nextToken()
            count -= 1
        }
    }
    
    func parseProgram() -> Program {
        let program = Program()

        while let curToken = currentToken, curToken.type != .EOF {
            do {
                let statement = try parseStatement()
                program.statements.append(statement)
                nextToken()
            } catch {
                errors.append(error)
                break
            }
        }
        
        return program
    }
    
    private func parseStatement() throws -> Statement {
        switch currentToken?.type {
        case .Let:
            return try parseLetStatement()
        case .Return:
            return try parseReturnStatement()
        default:
            return try parseExpressionStatement()
        }
    }
    
    private func parseIdentifierExpression() throws -> Expression {
        try expectTokenThrows(currentToken, .Identifier)
        return IdentifierExp(currentToken!)
    }
    
    private func parseExpression(_ precendence: Precedences) throws -> Expression {
        guard let prefixParserFunc = prefixParserFuncs[currentToken!.type] else {
            throw error.message("no prefix paser for token: \(currentToken!)")
        }

        var left = try prefixParserFunc()
        while peekToken!.type != .Semicolon && precendence < (operatorPrecedences[peekToken!.type] ?? .Lowest) {
            guard let infixParserFunc = infixParserFuncs[peekToken!.type] else {
                return left
            }
            
            nextToken()
            left = try infixParserFunc(left)
        }
        
        return left
    }

    fileprivate func parseInfixExpression(_ leftExp: Expression) throws -> InfixExpression {
        let operatorToken = currentToken!
        let precendence = operatorPrecedences[operatorToken.type] ?? .Lowest
        nextToken()
        return InfixExpression(operatorToken, leftExp, try parseExpression(precendence))
    }

    fileprivate func parsePrefixExpression() throws -> PrefixExpression {
        let token = currentToken!
        nextToken()

        return PrefixExpression(token, try parseExpression(.Prefix))
    }
}

//Statement
extension Parser {
    fileprivate func parseLetStatement() throws -> LetStatement {
        try expectTokenThrows(currentToken, .Let)
        let token = currentToken!

        try expectTokenThrows(peekToken, .Identifier)
        nextToken() // current -> identifier
        
        let identifierExp = IdentifierExp(currentToken!)

        try expectTokenThrows(peekToken, .Assign)
        nextToken(step: 2) // current -> ==, current -> value

        let valueExp = try parseExpression(.Lowest)
        if let fnExp = valueExp as? FunctionLiteral {
            fnExp.name = identifierExp.value
        }
        
        if expectToken(peekToken, .Semicolon) {
            nextToken() // current -> ;
        }
        
        return LetStatement(token, identifierExp, valueExp)
    }
    
    fileprivate func parseReturnStatement() throws -> ReturnStatement {
        try expectTokenThrows(currentToken, .Return)

        nextToken()
        let returnValue = try parseExpression(.Lowest)

        if peekToken?.type == .Semicolon {
            nextToken()
        }

        return ReturnStatement(returnValue: returnValue)
    }
    
    fileprivate func parseExpressionStatement() throws -> ExpressionStatement {
        let curToken = currentToken
        let expression = try parseExpression(.Lowest)

        if peekToken?.type == .Semicolon {
            nextToken()
        }
        
        return ExpressionStatement(curToken!, expression)
    }
}

//Experssion
extension Parser {
    fileprivate func parseIntegerLiteral() throws -> IntegerLiteral {
        try expectTokenThrows(currentToken, .Int)
        
        guard let value = Int(currentToken!.literal) else {
            throw error.notExpectedToken(expect: "Int value", actual: "\(currentToken!.literal)")
        }
        
        return IntegerLiteral(currentToken!, value)
    }
    
    fileprivate func parseBooleanLiteral() throws -> BooleanLiteral {
        guard expectToken(currentToken, .True) || expectToken(currentToken, .False) else {
            throw error.message("Expect token ture or false, actual is \(currentToken!.literal)")
        }
        
        guard let value = Bool(currentToken!.literal) else {
            throw error.notExpectedToken(expect: "Bool value", actual: "\(currentToken!.literal)")
        }
        
        return BooleanLiteral(currentToken!, value)
    }
    
    fileprivate func parseStringLiteral() throws -> Expression {
        try expectTokenThrows(currentToken, .String)
        return StringLiteral(currentToken!)
    }

    fileprivate func parseArrayLiteral() throws -> Expression {
        let exps = try parseExpressionList(endTokenType: .RightBracket)
        return ArrayLiteral(elements: exps)
    }

    fileprivate func parseGroupedExpression() throws -> Expression {
        nextToken()
        let exp = try parseExpression(.Lowest)

        try expectTokenThrows(peekToken, .RightParen)
        nextToken()

        return exp
    }

    fileprivate func parseIfExpression() throws -> IfExpression {
        try expectTokenThrows(peekToken, .LeftParen)
        nextToken(step: 2) //current jump over "if", current jump over "("

        let condition = try parseExpression(.Lowest)
        try expectTokenThrows(peekToken, .RightParen)
        nextToken() //jump to ")"

        try expectTokenThrows(peekToken, .LeftBrace)
        nextToken() //jump over "{"

        let consequence = try parseBlockStatement()
        var alternative: BlockStatement?

        if expectToken(peekToken, .Else) {
            nextToken() // current jump to "else"
            if expectToken(peekToken, .LeftBrace) {
                nextToken() // current jump to "{"
                alternative = try parseBlockStatement()
            }
        }

        return IfExpression(condition: condition, consequence: consequence, alternative: alternative)
    }

    fileprivate func parseBlockStatement() throws -> BlockStatement {
        var statements = [Statement]()

        nextToken() //current jump over "{"

        while !expectToken(currentToken, .RightBrace) && !expectToken(currentToken, .EOF) {
            let statement = try parseStatement()
            statements.append(statement)
            nextToken()
        }

        return BlockStatement(statements: statements)
    }

    fileprivate func parseFunctionParameters() throws -> [IdentifierExp] {
        var identifiers = [IdentifierExp]()
        if expectToken(peekToken, .RightParen) {
            nextToken() // current -> ")"
            return identifiers
        }

        nextToken()

        let identifier = IdentifierExp(currentToken!)
        identifiers.append(identifier)

        while expectToken(peekToken, .Comma) {
            nextToken(step: 2) //current jump to ",", current jump over ","
            let identifier = IdentifierExp(currentToken!)
            identifiers.append(identifier)
        }

        try expectTokenThrows(peekToken, .RightParen)
        nextToken() // current -> ")"

        return identifiers
    }

    fileprivate func parseFunctionLiteral() throws -> FunctionLiteral {
        try expectTokenThrows(peekToken, .LeftParen)
        nextToken() // current -> (

        let parameters = try parseFunctionParameters()

        try expectTokenThrows(peekToken, .LeftBrace)
        nextToken() // current -> {

        let body = try parseBlockStatement()
        return FunctionLiteral(parameters: parameters, body: body)
    }

    fileprivate func parseExpressionList(endTokenType: TokenType) throws -> [Expression] {
        var result = [Expression]()

        nextToken() // current jump to end token or first expression
        if expectToken(currentToken, endTokenType) {
            return result
        }

        while true {
            let exp = try parseExpression(.Lowest)
            result.append(exp)

            guard expectToken(peekToken, .Comma) else {
                break
            }

            nextToken(step: 2) // current jump to ","  current jump to next expression
        }

        try expectTokenThrows(peekToken, endTokenType)
        nextToken() // current -> end token

        return result
    }

    fileprivate func parseCallExpression(exp: Expression) throws -> CallExpression {
//        switch exp {
//        case is IdentifierExp, is FunctionLiteral, is CallExpression:
            let arguements = try parseExpressionList(endTokenType: .RightParen)
            return CallExpression(function: exp, arguements: arguements)
//        default:
//            throw error.notExpectExpression(expect: "\(FunctionLiteral.self) or \(IdentifierExp.self)", actual: "\(exp.self)")
//        }
    }

    fileprivate func parseIndexExpression(left: Expression) throws -> IndexExpression {
        nextToken() // current jump over "["
        let index = try parseExpression(.Lowest)

        let exp = IndexExpression(left: left, index: index)
        try expectTokenThrows(peekToken, .RightBracket)
        nextToken() // current jump to "]"
        return exp
    }

    fileprivate func parseHashLiteral() throws -> Expression {
        var pairs = [(key: Expression, value: Expression)]()
        while !expectToken(peekToken, .RightBrace) {
            nextToken()
            let key = try parseExpression(.Lowest)

            try expectTokenThrows(peekToken, .Colon)
            nextToken(step: 2) // current jump over ":"

            let value = try parseExpression(.Lowest)

            if !expectToken(peekToken, .RightBrace) && !expectToken(peekToken, .Comma) {
                throw error.notExpectedToken(expect: "\(TokenType.RightBrace.rawValue) or \(TokenType.Comma.rawValue)", actual: "\(peekToken?.type.rawValue ?? "")")
            }
            pairs.append((key: key, value: value))

            if expectToken(peekToken, .Comma) {
                nextToken() // current -> ","
            }
        }

        try expectTokenThrows(peekToken, .RightBrace)
        nextToken()

        return HashLiteral(pairs: pairs)
    }
}
