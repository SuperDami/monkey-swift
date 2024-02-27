//
//  Frame.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/03/24.
//

import Foundation

class Frame {
    let closure: ObjectImp.Closure
    var ip: Int = -1
    let basePointer: Int
    var instructions: BinaryInstructions { closure.fn.instructions }

    init(closure: ObjectImp.Closure, basePointer: Int) {
        self.closure = closure
        self.basePointer = basePointer
    }
}
