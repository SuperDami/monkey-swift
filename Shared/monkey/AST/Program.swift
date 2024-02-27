//
//  Program.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/23.
//

import Foundation

class Program: Node {
    let token = Token(.Illegal)
    var statements = [Statement]()
    
    func tokenLiteral() -> String {
        if statements.count > 0 {
            return statements[0].tokenLiteral()
        } else {
            return ""
        }
    }
    
    func string() -> String {
        var str = ""
        statements.forEach { statement in
            str += statement.string() + "\n"
        }
        
        return str
    }
}
