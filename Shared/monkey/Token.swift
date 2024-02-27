//
//  Token.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/23.
//

import Foundation

enum TokenType: String {
    case Illegal = "Illegal"
    case EOF = "EOF"
    
    case Identifier = "identifier"
    case Int = "int"
    case String = "string"
    
    case Assign = "="
    case Plus = "+"
    case Minus = "-"
    case Bang = "!"
    case Asterisk = "*"
    case Slash = "/"
    case Equal = "=="
    case NotEqual = "!="
    case LessThan = "<"
    case GreaterThan = ">"
    case Comma = ","
    case Semicolon = ";"
    case Colon = ":"    
    case LeftParen = "("
    case RightParen = ")"
    case LeftBrace = "{"
    case RightBrace = "}"
    case LeftBracket = "["
    case RightBracket = "]"
    
    case Function = "fn"
    case Let = "let"
    case True = "true"
    case False = "false"
    case If = "if"
    case Else = "else"
    case Return = "return"
    
    static let keywords = [
        Function.rawValue: Function,
        Let.rawValue: Let,
        True.rawValue: True,
        False.rawValue: False,
        If.rawValue: If,
        Else.rawValue: Else,
        Return.rawValue: Return
    ]
    
    static let symbols = [
        Assign.rawValue: Assign,
        Plus.rawValue: Plus,
        Minus.rawValue: Minus,
        Bang.rawValue: Bang,
        Asterisk.rawValue: Asterisk,
        Slash.rawValue: Slash,
        Equal.rawValue: Equal,
        NotEqual.rawValue: NotEqual,
        LessThan.rawValue: LessThan,
        GreaterThan.rawValue: GreaterThan,
        Comma.rawValue: Comma,
        Semicolon.rawValue: Semicolon,
        Colon.rawValue: Colon,
        LeftParen.rawValue: LeftParen,
        RightParen.rawValue: RightParen,
        LeftBrace.rawValue: LeftBrace,
        RightBrace.rawValue: RightBrace,
        LeftBracket.rawValue: LeftBracket,
        RightBracket.rawValue: RightBracket
    ]
    
    static func lookupIdentifierType(_ identify: String) -> TokenType {
        if let type = keywords[identify] {
            return type
        }
        
        return .Identifier
    }
}

struct Token {
    let type: TokenType
    let literal: String
    
    init(_ type: TokenType, _ literal: String) {
        self.type = type
        self.literal = literal
    }
    
    init(_ type: TokenType) {
        self.type = type
        self.literal = type.rawValue
    }
}
