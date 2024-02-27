//
//  lexer.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/22.
//

import Foundation

class Lexer {
    var input: [Character]
    private var position = 0
    private var char: Character? {
        get {
            return position < input.count ? input[position] : nil
        }
    }
    
    private var nextChar: Character? {
        get { position + 1 < input.count ? input[position + 1] : nil }
    }
    
    init(_ code: String) {
        input = Array(code)
    }
    
    private func movePosition(offset: Int = 1) {
        if position + offset <= input.count {
            position += offset
        }
    }
    
    private func skipWhite() {
        while char == Character(" ") || char == Character("\t") || char == Character("\n") || char == Character("\r") {
            movePosition()
        }
    }
    
    private func readString() -> String {
        defer { movePosition() }
        let start = position
        while char != "\"" {
            movePosition()
        }
        
        if position - 1 < start {
            return ""
        }
        return String(input[start...position - 1])
    }
    
    private func readNumber() -> String {
        let start = position
        while char?.isNumber ?? false {
            movePosition()
        }
        
        return String(input[start...position - 1])
    }
    
    private func readIdentify() -> String {
        let start = position
        while let c = char, (c.isLetter || c.isNumber) { // first char is certainly a letter
            movePosition()
        }
        
        return String(input[start...position - 1])
    }
    
    func nextToken() -> Token {
        skipWhite()
        guard let c = char else {
            movePosition()
            return Token(.EOF, "")
        }
        
        if let nextChar = nextChar {
            if c == "=" && nextChar == "=" {
                movePosition(offset: 2)
                return Token(.Equal)
            } else if c == "!" && nextChar == "=" {
                movePosition(offset: 2)
                return Token(.NotEqual)
            }
        }
        
        if c.isLetter {
            let str = readIdentify()
            return Token(TokenType.lookupIdentifierType(str), str)
        } else if c.isNumber {
            return Token(.Int, readNumber())
        } else if c == "\"" {
            movePosition()
            let str = readString()
            return Token(.String, str)
        }

        if let type = TokenType.symbols[String(c)] {
            movePosition()
            return Token(type, type.rawValue)
        } else {
            movePosition()
            return Token(.Illegal, "")
        }
    }
}


