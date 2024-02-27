//
//  CompilerTest.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/04/22.
//

import XCTest

final class CompilerTest: XCTestCase {
    typealias TestPayload = (input: String, expectedConstants: [Any], expectedInstructions: [BinaryInstructions])
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIntegerArithmetic() throws {
        let tests: [TestPayload] = [
            (
                input: "1 + 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .add),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1; 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .pop),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1 * 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .mutiple),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1 / 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .divide),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1 > 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .greaterThan),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1 < 2",
                expectedConstants: [2, 1],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .greaterThan),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1 == 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .equal),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "1 != 2",
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .notEqual),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "true == false",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .falseConstant),
                    Code.make(op: .equal),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "true != false",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .falseConstant),
                    Code.make(op: .notEqual),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "-1",
                expectedConstants: [1],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .minus),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testBooleanExpressions() throws {
        let tests: [TestPayload] = [
            (
                input: "true",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "false",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .falseConstant),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "!true",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .bang),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "!true",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .bang),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "!false",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .falseConstant),
                    Code.make(op: .bang),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testConditionals() throws {
        let tests: [TestPayload] = [
            (
                input: "if (true) { 10 }; 3333;",
                expectedConstants: [10, 3333],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .jumpNotTrurhy, operands: [10]),
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .jump, operands: [11]),
                    Code.make(op: .nullConstant),
                    Code.make(op: .pop),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "if (true) { 10 } else { 20 }; 3333",
                expectedConstants: [10, 20, 3333],
                expectedInstructions: [
                    Code.make(op: .trueConstant),
                    Code.make(op: .jumpNotTrurhy, operands: [10]),
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .jump, operands: [13]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .pop),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testGlobalLetStatements() throws {
        let tests: [TestPayload] = [
            (
                input: """
                let one = 1;
                let two = 2;
                """,
                expectedConstants: [1, 2],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .setGlobal, operands: [1]),
                ]
            ),
            (
                input: """
                let one = 1;
                one;
                """,
                expectedConstants: [1],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .getGlobal, operands: [0]),
                    Code.make(op: .pop),
                ]
            ),
            (
                input: """
                let one = 1;
                let two = one;
                two;
                """,
                expectedConstants: [1],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .getGlobal, operands: [0]),
                    Code.make(op: .setGlobal, operands: [1]),
                    Code.make(op: .getGlobal, operands: [1]),
                    Code.make(op: .pop),
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testStringExpression() throws {
        let tests: [TestPayload] = [
            (
                input: "\"monkey\"",
                expectedConstants: ["monkey"],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "\"mon\" + \"key\"",
                expectedConstants: ["mon", "key"],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .add),
                    Code.make(op: .pop)
                ]
            ),
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testArrayLiterals() throws {
        let tests: [TestPayload] = [
            (
                input: "[]",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .array, operands: [0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "[1, 2, 3]",
                expectedConstants: [1, 2, 3],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .array, operands: [3]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "[1 + 2, 3 - 4, 5 * 6]",
                expectedConstants: [1, 2, 3, 4, 5, 6],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .add),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .sub),
                    Code.make(op: .constant, operands: [4]),
                    Code.make(op: .constant, operands: [5]),
                    Code.make(op: .mutiple),
                    Code.make(op: .array, operands: [3]),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testHashLiterals() throws {
        let tests: [TestPayload] = [
            (
                input: "{}",
                expectedConstants: [],
                expectedInstructions: [
                    Code.make(op: .hash, operands: [0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "{1: 2, 3: 4, 5: 6}",
                expectedConstants: [1, 2, 3, 4, 5, 6],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .constant, operands: [4]),
                    Code.make(op: .constant, operands: [5]),
                    Code.make(op: .hash, operands: [6]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "{1: 2 + 3, 4: 5 * 6}",
                expectedConstants: [1, 2, 3, 4, 5, 6],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .add),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .constant, operands: [4]),
                    Code.make(op: .constant, operands: [5]),
                    Code.make(op: .mutiple),
                    Code.make(op: .hash, operands: [4]),
                    Code.make(op: .pop)
                ]
            ),
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testIndexExpressions() throws {
        let tests: [TestPayload] = [
            (
                input: "[1, 2, 3][1 + 1]",
                expectedConstants: [1, 2, 3, 1, 1],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .array, operands: [3]),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .constant, operands: [4]),
                    Code.make(op: .add),
                    Code.make(op: .index),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "{1: 2}[2 - 1]",
                expectedConstants: [1, 2, 2, 1],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .hash, operands: [2]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .sub),
                    Code.make(op: .index),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testFunctions() throws {
        let tests: [TestPayload] = [
            (
                input: "fn() { return 5 + 10 }",
                expectedConstants: [
                    5,
                    10,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .constant, operands: [1]),
                        Code.make(op: .add),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [2, 0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "fn() { 5 + 10 }",
                expectedConstants: [
                    5,
                    10,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .constant, operands: [1]),
                        Code.make(op: .add),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [2, 0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: "fn() { 1; 2 }",
                expectedConstants: [
                    1,
                    2,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .pop),
                        Code.make(op: .constant, operands: [1]),
                        Code.make(op: .returnValue),
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [2, 0]),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testCompilerScopes() throws {
        var globalSymbolTable = SymbalTable()
        var constants = [Object]()
        let compiler = Compiler.initWithState(constants: &constants, symbolTable: &globalSymbolTable)

        XCTAssertEqual(compiler.scopeIndex, 0)
        compiler.emit(opCode: .minus)
        compiler.enterScope()
        XCTAssertEqual(compiler.scopeIndex, 1)
        compiler.emit(opCode: .sub)

        let lastIns = compiler.scopes[compiler.scopeIndex].lastInstruction
        XCTAssertEqual(lastIns!.opCode, .sub)
        XCTAssertTrue(compiler.symbolTable.outer === globalSymbolTable)

        let _ = compiler.leaveScope()
        XCTAssertEqual(compiler.scopeIndex, 0)
        XCTAssertTrue(compiler.symbolTable === globalSymbolTable)
        XCTAssertTrue(compiler.symbolTable.outer === nil)

        compiler.emit(opCode: .add)
        XCTAssertEqual(compiler.scopes[compiler.scopeIndex].instructions.count, 2) // 2 bits Instructions: .minus .add

        XCTAssertEqual(compiler.scopes[compiler.scopeIndex].lastInstruction!.opCode, .add)
        XCTAssertEqual(compiler.scopes[compiler.scopeIndex].previousInstruction!.opCode, .minus)
    }

    func testFunctionsWithoutReturnValue() throws {
        let tests: [TestPayload] = [
            (
                input: "fn() { }",
                expectedConstants: [
                    [
                        Code.make(op: .returnNone)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [0, 0]),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testFunctionCalls() throws {
        let tests: [TestPayload] = [
            (
                input: "fn() { 24 }();",
                expectedConstants: [
                    24,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [1, 0]),  // 1 local binding, 0 arguments, insert into stack
                    Code.make(op: .call, operands: [0]),        // 0 argument count, call from top of stack, result insert into stack
                    Code.make(op: .pop)                         // Pop result from top of stack
                ]
            ),
            (
                input: """
                    let noArg = fn() { 24 };
                    noArg();
                """,
                expectedConstants: [
                    24,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [1, 0]), // Constant position 0, freeSymbol count 0, insert into stack
                    Code.make(op: .setGlobal, operands: [0]),  // Get from top of stack, set into symbol table
                    Code.make(op: .getGlobal, operands: [0]),  // Get closure insert into stack
                    Code.make(op: .call, operands: [0]),       // Call from top of stack, result insert into stack
                    Code.make(op: .pop)                        // Pop result from top of stack
                ]
            ),
            (
                input: """
                    let manyArg = fn(a, b, c) { };
                    manyArg(24, 25, 26);
                """,
                expectedConstants: [
                    [
                        Code.make(op: .returnNone)
                    ],
                    24,
                    25,
                    26
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [0, 0]), // Constant position 0, freeSymbol count 0
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .getGlobal, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .call, operands: [3]),
                    Code.make(op: .pop),
                ]
            ),
            (
                input: """
                    let oneArg = fn(a) { a };
                    oneArg(24);
                """,
                expectedConstants: [
                    [
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .returnValue)
                    ],
                    24
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [0, 0]), // Constant position 0, freeSymbol count 0
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .getGlobal, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .call, operands: [1]),
                    Code.make(op: .pop),
                ]
            ),
            (
                input: """
                    let manyArg = fn(a, b, c) { a; b; c; };
                    manyArg(24, 25, 26);
                """,
                expectedConstants: [
                    [
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .pop),
                        Code.make(op: .getLocal, operands: [1]),
                        Code.make(op: .pop),
                        Code.make(op: .getLocal, operands: [2]),
                        Code.make(op: .returnValue)
                    ],
                    24,
                    25,
                    26
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [0, 0]), // Constant position 0, freeSymbol count 0
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .getGlobal, operands: [0]),
                    Code.make(op: .constant, operands: [1]),
                    Code.make(op: .constant, operands: [2]),
                    Code.make(op: .constant, operands: [3]),
                    Code.make(op: .call, operands: [3]),
                    Code.make(op: .pop),
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testLetStatementScopes() throws {
        let tests: [TestPayload] = [
            (
                input: """
                    let num = 55;
                    fn() { num }
                """,
                expectedConstants: [
                    55,
                    [
                        Code.make(op: .getGlobal, operands: [0]),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .closure, operands: [1, 0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input: """
                    fn() {
                        let num = 55;
                        num
                    }
                """,
                expectedConstants: [
                    55,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .setLocal, operands: [0]),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [1, 0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input:"""
                    fn() {
                        let a = 55;
                        let b = 77;
                        a + b
                    }
                """,
                expectedConstants: [
                    55,
                    77,
                    [
                        Code.make(op: .constant, operands: [0]),
                        Code.make(op: .setLocal, operands: [0]),
                        Code.make(op: .constant, operands: [1]),
                        Code.make(op: .setLocal, operands: [1]),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .getLocal, operands: [1]),
                        Code.make(op: .add),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [2, 0]),
                    Code.make(op: .pop)
                ]
            ),
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }

    func testClosure() throws {
        let tests: [TestPayload] = [
            (
                input:"""
                    fn(a) {
                        fn(b) {
                            a + b
                        }
                    }
                """,
                expectedConstants: [
                    [
                        Code.make(op: .getFree, operands: [0]),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .add),
                        Code.make(op: .returnValue)
                    ],
                    [
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .closure, operands: [0, 1]), // Constant position 0, freeSymbol count 1
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [1, 0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input:"""
                    fn(a) {
                        fn(b) {
                            fn(c) {
                                a + b + c
                            }
                        }
                    }
                """,
                expectedConstants: [
                    [
                        Code.make(op: .getFree, operands: [0]),
                        Code.make(op: .getFree, operands: [1]),
                        Code.make(op: .add),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .add),
                        Code.make(op: .returnValue)
                    ],
                    [
                        Code.make(op: .getFree, operands: [0]),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .closure, operands: [0, 2]),
                        Code.make(op: .returnValue)
                    ],
                    [
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .closure, operands: [1, 1]),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .closure, operands: [2, 0]),
                    Code.make(op: .pop)
                ]
            ),
            (
                input:"""
                    let global = 55;
                    fn() {
                        let a = 66;
                        fn() {
                            let b = 77;

                            fn () {
                                let c = 88;
                                global + a + b + c;
                            }
                        }
                    }
                """,
                expectedConstants: [
                    55,
                    66,
                    77,
                    88,
                    [
                        Code.make(op: .constant, operands: [3]),
                        Code.make(op: .setLocal, operands: [0]),
                        Code.make(op: .getGlobal, operands: [0]),
                        Code.make(op: .getFree, operands: [0]),
                        Code.make(op: .add),
                        Code.make(op: .getFree, operands: [1]),
                        Code.make(op: .add),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .add),
                        Code.make(op: .returnValue)
                    ],
                    [
                        Code.make(op: .constant, operands: [2]),
                        Code.make(op: .setLocal, operands: [0]),
                        Code.make(op: .getFree, operands: [0]),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .closure, operands: [4, 2]),
                        Code.make(op: .returnValue)
                    ],
                    [
                        Code.make(op: .constant, operands: [1]),
                        Code.make(op: .setLocal, operands: [0]),
                        Code.make(op: .getLocal, operands: [0]),
                        Code.make(op: .closure, operands: [5, 1]),
                        Code.make(op: .returnValue)
                    ]
                ],
                expectedInstructions: [
                    Code.make(op: .constant, operands: [0]),
                    Code.make(op: .setGlobal, operands: [0]),
                    Code.make(op: .closure, operands: [6, 0]),
                    Code.make(op: .pop)
                ]
            )
        ]

        for test in tests {
            try runCompilerTest(payload: test)
        }
    }
}

extension CompilerTest {
    private func runCompilerTest(payload: TestPayload) throws {
        let compiler = try createCompiler(input: payload.input)
        let byteCode = compiler.byteCode()

        verifyConstants(expects: payload.expectedConstants, acturals: byteCode.constants)
        verifyInstructions(expects: payload.expectedInstructions, actural: byteCode.instructions)
    }

    private func createCompiler(input: String) throws -> Compiler {
        let program = REPL.createProgram(input: input)
        var constants = [Object]()
        var symbolTable = SymbalTable()
        let compiler = Compiler.initWithState(constants: &constants, symbolTable: &symbolTable)
        try compiler.compiler(node: program)

        return compiler
    }

    private func verifyInstructions(expects: [BinaryInstructions], actural: BinaryInstructions) {
        var concated = BinaryInstructions()
        for ins in expects {
            concated.append(ins)
        }

        XCTAssertEqual(concated, actural, """
                       expect:  \(Array(concated))
                       actural: \(Array(actural))
                       expect decode:  \(concated.string())
                       actural decode: \(actural.string())
                       """)
    }

    private func verifyConstants(expects: [Any], acturals: [Object]) {
        for i in 0..<expects.count {
            let expected = expects[i]
            let actural = acturals[i]
            switch expected {
            case is Int:
                let intObject = actural as! ObjectImp.Integer
                XCTAssertEqual(intObject.value, Int64(expected as! Int))
            case is String:
                let stringObject = actural as! ObjectImp.String
                XCTAssertEqual(stringObject.value, expected as! String)
            case is [BinaryInstructions]:
                let ins = actural as! ObjectImp.CompiledFunction
                verifyInstructions(expects: expected as! [BinaryInstructions], actural: ins.instructions)
            default:
                XCTFail("Invalid expect value \(expected)")
            }
        }
    }
}

