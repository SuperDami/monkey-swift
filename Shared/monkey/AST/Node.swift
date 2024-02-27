//
//  Node.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/23.
//

import Foundation

protocol Node {
    var token: Token { get }

    func tokenLiteral() -> String
    func string() -> String
}

extension Node {
    func tokenLiteral() -> String {
        return token.literal
    }
}
