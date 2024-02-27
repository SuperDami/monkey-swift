//
//  main.swift
//  monkey-REPL
//
//  Created by zhejun chen on 2023/04/12.
//

import Foundation

print("Hello, Monkey!")
let theREPL = REPL()
let executor = theREPL.startCompiling()
print("Try you monkey code:")
var allinput = ""

while true {
    guard let inputLine = readLine() else {
        continue
    }

    feedInput(inputLine)
}

func feedInput(_ input: String) {
    allinput += input
    let stashedInput = allinput
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.7, execute: DispatchWorkItem(block: {
        guard stashedInput == allinput else { return }
        executor(allinput)
        allinput = ""
    }))
}
