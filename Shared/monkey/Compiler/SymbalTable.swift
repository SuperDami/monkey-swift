//
//  SymbalTable.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/02/26.
//

import Foundation

enum SymbolScope: String {
    case global, local, builtin, free, function
}

struct Symbol {
    let name: String
    let scope: SymbolScope
    var index: Int
}

class SymbalTable {
    enum error: Error {
        case duplicateDefineName
        case undefinedName
    }

    let outer: SymbalTable?
    private var store = [String: Symbol]()
    private(set) var freeSymbols = [Symbol]()
    var numDefinitions: Int { store.count }

    init(outer: SymbalTable? = nil) {
        self.outer = outer
    }

    @discardableResult
    func define(name: String) throws -> Symbol {
        if store[name] != nil {
            throw error.duplicateDefineName
        }

        let scope = outer == nil ? SymbolScope.global : SymbolScope.local
        let symbol = Symbol(name: name, scope: scope, index: numDefinitions)
        store[name] = symbol
        return symbol
    }

    @discardableResult
    func resolve(name: String) throws -> Symbol {
        guard let symbol = store[name] else {
            guard let outerSymbol = try outer?.resolve(name: name) else {
                throw error.undefinedName
            }

            if outerSymbol.scope == .global || outerSymbol.scope == .builtin {
                return outerSymbol
            }

            let free = defineFree(original: outerSymbol)
            return free
        }
        return symbol
    }

    @discardableResult
    func defineBuiltin(index: Int, name: String) -> Symbol {
        let symbol = Symbol(name: name, scope: .builtin, index: index)
        store[name] = symbol
        return symbol
    }

    @discardableResult
    func defineFree(original: Symbol) -> Symbol {
        freeSymbols.append(original)
        let repleaceFree = Symbol(name: original.name, scope: .free, index: freeSymbols.count - 1)
        store[original.name] = repleaceFree
        return repleaceFree
    }

    @discardableResult
    func defineFunctionName(name: String) -> Symbol {
        let symbol = Symbol(name: name, scope: .function, index: 0)
        store[name] = symbol
        return symbol
    }
}
