//
//  VMTest.swift
//  monkey-swift
//
//  Created by zhejun chen on 2023/05/10.
//

import XCTest

final class VMTest: XCTestCase {
    typealias TestPayload = (input: String, expected: Any)
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIntegerArithmetic() throws {
        let tests: [TestPayload] = [
            ("1", 1),
            ("2", 2),
            ("1 + 2", 3),
            ("1 - 2", -1),
            ("1 * 2", 2),
            ("4 / 2", 2),
            ("50 / 2 * 2 + 10 - 5", 55),
            ("5 * (2 + 10)", 60),
            ("5 + 5 + 5 + 5 - 10", 10),
            ("2 * 2 * 2 * 2 * 2", 32),
            ("5 * 2 + 10", 20),
            ("5 + 2 * 10", 25),
            ("5 * (2 + 10)", 60),
            ("-5", -5),
            ("-10", -10),
            ("-50 + 100 + -50", 0),
            ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
        ]

        try runVMTests(tests: tests)
    }

    func testBooleanExpressions() throws {
        let tests: [TestPayload] = [
            ("true", true),
            ("false", false),
            ("1 < 2", true),
            ("1 > 2", false),
            ("1 < 1", false),
            ("1 > 1", false),
            ("1 == 1", true),
            ("1 != 1", false),
            ("1 == 2", false),
            ("1 != 2", true),
            ("true == true", true),
            ("false == false", true),
            ("true == false", false),
            ("true != false", true),
            ("false != true", true),
            ("(1 < 2) == true", true),
            ("(1 < 2) == false", false),
            ("(1 > 2) == true", false),
            ("(1 > 2) == false", true),
            ("!true", false),
            ("!false", true),
//            ("!5", false),
            ("!!true", true),
            ("!!false", false),
//            ("!!5", true),
            ("!(if (false) { 5; })", true),
        ]

        try runVMTests(tests: tests)
    }

    func testConditionals() throws {
        let tests: [TestPayload] = [
            ("if (true) { 10 }", 10),
            ("if (true) { 10 } else { 20 }", 10),
            ("if (false) { 10 } else { 20 }", 20),
//            ("if (1) { 10 }", 10),
            ("if (1 < 2) { 10 }", 10),
            ("if (1 < 2) { 10 } else { 20 }", 10),
            ("if (1 > 2) { 10 } else { 20 }", 20),
            ("if (1 > 2) { 10 }", ObjectImp.Null()),
            ("if (false) { 10 }",  ObjectImp.Null()),
            ("if ((if (false) { 10 })) { 10 } else { 20 }", 20),
        ]

        try runVMTests(tests: tests)
    }

    func testGlobalLetStatements() throws {
        let tests: [TestPayload] = [
            ("let one = 1; one", 1),
            ("let one = 1; let two = 2; one + two", 3),
            ("let one = 1; let two = one + one; one + two", 3),
        ]

        try runVMTests(tests: tests)
    }

    func testStringExpressions() throws {
        let tests: [TestPayload] = [
            ("\"monkey\"", "monkey"),
            ("\"mon\" + \"key\"", "monkey"),
            ("\"mon\" + \"key\" + \"banana\"", "monkeybanana"),
        ]

        try runVMTests(tests: tests)
    }

    func testArrayLiterals() throws {
        let tests: [TestPayload] = [
            ("[]", []),
            ("[1, 2, 3]", [1, 2, 3]),
            ("[1 + 2, 3 * 4, 5 + 6]", [3, 12, 11]),
        ]

        try runVMTests(tests: tests)
    }

    func testHashLiterals() throws {
        let tests: [TestPayload] = [
            (
                "{}", [:]
            ),
            (
                "{1: 2, 2: 3}",
                [1: 2, 2: 3]
            ),
            (
                "{1 + 1: 2 * 2, 3 + 3: 4 * 4}",
                [2: 4, 6: 16]
            )
        ]
        try runVMTests(tests: tests)
    }

    func testAccessHash() throws {
        let tests: [TestPayload] = [
            (
                "let a = {}",
                [:]
            ),
            (
                """
                let a = {1: 2, 2: 3};
                a[1]
                """,
                2
            ),
            (
                """
                let b = {1 + 1: 2 * 2, 3 + 3: 4 * 4}
                b[3 + 3]
                """,
                16
            )
        ]
        try runVMTests(tests: tests)
    }

    func testIndexExpressions() throws {
        let tests: [TestPayload] = [
            ("[1, 2, 3][1]", 2),
            ("[1, 2, 3][0 + 2]", 3),
            ("[[1, 1, 1]][0][0]", 1),
            ("[][0]", ObjectImp.Null()),
            ("[1, 2, 3][99]", ObjectImp.Null()),
            ("[1][-1]", ObjectImp.Null()),
            ("{1: 1, 2: 2}[1]", 1),
            ("{1: 1, 2: 2}[2]", 2),
            ("{1: 1}[0]", ObjectImp.Null()),
            ("{}[0]", ObjectImp.Null()),
        ]
        try runVMTests(tests: tests)
    }

    func testCallingFunctionsWithoutArguments() throws {
        let tests: [TestPayload] = [
            (
                """
                let fivePlusTen = fn() { 5 + 10; };
                fivePlusTen();
                """,
                15
            ),
            (
                """
                let one = fn() { 1; };
                let two = fn() { 2; };
                one() + two()
                """,
                3
            ),
            (
                """
                let a = fn() { 1 };
                let b = fn() { a() + 1 };
                let c = fn() { b() + 1 };
                c();
                """,
                3
            ),
            (
                """
                let earlyExit = fn() { return 99; 100; };
                earlyExit();
                """,
                99
            ),
            (
                """
                let earlyExit = fn() { return 99; return 100; };
                earlyExit();
                """,
                99
            ),
            (
                """
                let noReturn = fn() { };
                noReturn();
                """,
                ObjectImp.Null()
            ),
            (
                """
                let noReturn = fn() { };
                let noReturnTwo = fn() { noReturn(); };
                noReturn();
                noReturnTwo();
                """,
                ObjectImp.Null()
            )
        ]

        try runVMTests(tests: tests)
    }

    func testFirstClassFunctions() throws {
        let tests: [TestPayload] = [
            (
                """
                let returnsOne = fn() { 1; };
                let returnsOneReturner = fn() { returnsOne; };
                returnsOneReturner()();
                """,
                1
            ),
            (
                """
                let returnsOneReturner = fn() {
                    let returnsOne = fn() { 1; };
                    returnsOne;
                };
                returnsOneReturner()();
                """,
                1
            ),
        ]

        try runVMTests(tests: tests)
    }

    func testCallingFunctionsWithBindings() throws {
        let tests: [TestPayload] = [
            (
                """
                let one = fn() { let one = 1; one };
                one();
                """,
                1
            ),
            (
                """
                let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
                oneAndTwo();
                """,
                3
            ),
            (
                """
                let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
                let threeAndFour = fn() { let three = 3; let four = 4; three + four; };
                oneAndTwo() + threeAndFour();
                """,
                10
            ),
            (
                """
                let firstFoobar = fn() { let foobar = 50; foobar; };
                let secondFoobar = fn() { let foobar = 100; foobar; };
                firstFoobar() + secondFoobar();
                """,
                150
            ),
            (
                """
                let globalSeed = 50;
                let minusOne = fn() {
                    let num = 1;
                    globalSeed - num;
                }
                let minusTwo = fn() {
                    let num = 2;
                    globalSeed - num;
                }
                minusOne() + minusTwo();
                """,
                97
            ),
        ]

        try runVMTests(tests: tests)
    }

    func testCallingFunctionsWithArgumentsAndBindings() throws {
        let tests: [TestPayload] = [
            (
                """
                let identity = fn(a) { a; };
                identity(4);
                """,
                4
            ),
            (
                """
                let sum = fn(a, b) { a + b; };
                sum(1, 2);
                """,
                3
            ),
            (
                """
                let sum = fn(a, b) {
                    let c = a + b;
                    c;
                };
                sum(1, 2);
                """,
                3
            ),
            (
                """
                let sum = fn(a, b) {
                    let c = a + b;
                    c;
                };
                sum(1, 2) + sum(3, 4);
                """,
                10
            ),
            (
                """
                let sum = fn(a, b) {
                    let c = a + b;
                    c;
                };
                let outer = fn() {
                    sum(1, 2) + sum(3, 4);
                }
                outer();
                """,
                10
            ),
            (
                """
                let globalNum = 10;

                let sum = fn(a, b) {
                    let c = a + b;
                    c + globalNum;
                };

                let outer = fn() {
                    sum(1, 2) + sum(3, 4) + globalNum;
                }
                outer() + globalNum;
                """,
                50
            ),
        ]

        try runVMTests(tests: tests)
    }

//TODO func testBuiltinFunctions() {

    func testClosures() throws {
        let tests: [TestPayload] = [
            (
                """
                let newClosure = fn(a) {
                    fn() { a; };
                };
                let closure = newClosure(99);
                closure();
                """,
                99
            ),
            (
                """
                let newAdder = fn(a, b) {
                    fn(c) { a + b + c };
                };
                let adder = newAdder(1, 2);
                adder(8);
                """,
                11
            ),
            (
                """
                let newAdder = fn(a, b) {
                    let c = a + b;
                    fn(d) { c + d };
                };
                let adder = newAdder(1, 2);
                adder(8);
                """,
                11
            ),
            (
                """
                let newAdderOuter = fn(a, b) {
                    let c = a + b;
                    fn(d) {
                        let e = d + c;
                        fn(f) { e + f; };
                    };
                };
                let newAdderInner = newAdderOuter(1, 2)
                let adder = newAdderInner(3);
                adder(8);
                """,
                14
            ),
            (
                """
                let a = 1;
                let newAdderOuter = fn(b) {
                    fn(c) {
                        fn(d) { a + b + c + d };
                    };
                };
                let newAdderInner = newAdderOuter(2)
                let adder = newAdderInner(3);
                adder(8);
                """,
                14
            ),
            (
                """
                let newClosure = fn(a, b) {
                    let one = fn() { a; };
                    let two = fn() { b; };
                    fn() { one() + two(); };
                };
                let closure = newClosure(9, 90);
                closure();
                """,
                99
            )
        ]

        try runVMTests(tests: tests)
    }

    func testRecursiveFibonacci() throws {
        let tests: [TestPayload] = [
            (
                input: """
                let fibonacci = fn(x) {
                    if (x == 0) {
                        return 0;
                    } else {
                        if (x == 1) {
                            return 1;
                        } else {
                            fibonacci(x - 1) + fibonacci(x - 2);
                        }
                    }
                };
                fibonacci(15);
                """,
                610
            ),
        ]

        try runVMTests(tests: tests)
    }
}

extension VMTest {
    fileprivate func runVMTests(tests: [TestPayload]) throws {
        for test in tests {
            let vm = try createVM(input: test.input)
            try vm.run()
            try validateValueWithExpected(value: vm.lastPoped, expected: test.expected)
        }
    }

    private func createVM(input: String) throws -> VM {
        let program = REPL.createProgram(input: input)
        var constants = [Object]()
        var symbolTable = SymbalTable()
        let compiler = Compiler.initWithState(constants: &constants, symbolTable: &symbolTable)
        try compiler.compiler(node: program)

        var globalVariables: [Object] = Array(repeating: ObjectImp.Integer(value: 0), count: VM.globalVariableNumber)
        let vm = VM.new(byteCode: compiler.byteCode(), globalsVariables: &globalVariables)
        return vm
    }

    fileprivate func validateValueWithExpected(value: Object, expected: Any) throws {
        switch expected {
        case is Int:
            let intObject = value as! ObjectImp.Integer
            XCTAssertEqual(Int64(expected as! Int), intObject.value)
        case is Bool:
            let boolObject = value as! ObjectImp.Boolean
            XCTAssertEqual(expected as! Bool, boolObject.value)
        case is String:
            let stringObject = value as! ObjectImp.String
            XCTAssertEqual(expected as! String, stringObject.value)
        case is Array<Any>:
            let arrayObject = value as! ObjectImp.Array
            let expectedArray = expected as! Array<Any>
            XCTAssertEqual(expectedArray.count, arrayObject.elements.count)
            for i in 0..<expectedArray.count {
                try validateValueWithExpected(value: arrayObject.elements[i], expected: expectedArray[i])
            }
        case is Dictionary<AnyHashable, Any>:
            let hashObject = value as! ObjectImp.Hash
            let expectedHash = expected as! Dictionary<AnyHashable, Any>
            XCTAssertEqual(hashObject.map.count, expectedHash.count)

            for intKey in hashObject.map.keys {
                let hashPair = hashObject.map[intKey]!
                let rawKeyValue = hashPair.key.value as! (any Hashable)
                try validateValueWithExpected(value: hashPair.value, expected: expectedHash[AnyHashable(rawKeyValue)]!)
            }
        case is ObjectImp.Null:
            let nilObject = value as! ObjectImp.Null
            XCTAssertEqual(nilObject.type, .NullObj)
        default:
            XCTFail("Invalid expect value \(expected)")
        }
    }
}
