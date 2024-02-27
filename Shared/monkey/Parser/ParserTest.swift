//
//  parset_Test.swift
//  monkey-swift
//
//  Created by Zhejun Chen on 2022/07/31.
//

import XCTest

class ParserTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLetStatement() throws {
        let tests: [(String, String, Any)] = [
            ("let x = 5;", "x", 5),
            ("let y = true;", "y", true),
            ("let foobar = y;", "foobar", "y"),
            ("let foobar123 = y;", "foobar123", "y"),
        ]
        
        for test in tests {
            let lexer = Lexer(test.0)
            let parser = Parser(lexer)
            let program = parser.parseProgram()

            assert(parser.errors.count == 0, "Parse errors: \(parser.errors)")
            assert(program.statements.count == 1, "Statement count error: \(program.statements.count)")
                        
            verifyLetStatement(program.statements[0], test.1)
        }
    }

    func testIdentifierExpression() throws {
        let input = "foobar;"
        let program = REPL.createProgram(input: input)
        XCTAssertEqual(program.statements.count, 1)
        let expression = program.statements[0] as! ExpressionStatement

        testIdentifier(exp: expression.expression as! IdentifierExp, value: "foobar")
    }

    func testIntegerLiteralExpression() throws {
        let program = REPL.createProgram(input: "5;")
        XCTAssertEqual(program.statements.count, 1)
        let expression = program.statements[0] as! ExpressionStatement
        let integeral = expression.expression as! IntegerLiteral

        XCTAssertEqual(integeral.value, 5)
        XCTAssertEqual(integeral.tokenLiteral(), "5")
    }

    func testParsingPrefixExpression() throws {
        typealias TestPayload = (input: String, operator: String, value: Any)
        let prefixTests: [TestPayload] = [
            ("!5;", "!", 5),
            ("-5;", "-", 5),
            ("!true;", "!", true),
            ("!false;", "!", false),
        ]

        for test in prefixTests {
            let program = REPL.createProgram(input: test.input)
            let expression = program.statements[0] as! ExpressionStatement
            let prefixExp = expression.expression as! PrefixExpression

            XCTAssertEqual(prefixExp.op, test.operator)
            switch test.value.self {
            case is Int:
                let integerLiteral = prefixExp.right as! IntegerLiteral
                XCTAssertEqual(integerLiteral.value, test.value as! Int)
            case is Bool:
                let boolLiteral = prefixExp.right as! BooleanLiteral
                XCTAssertEqual(boolLiteral.value, test.value as! Bool)
            default:
                XCTFail()
            }
        }
    }

    func testParsingInfixExpression() throws {
        typealias TestPayload = (input: String, operator: String, leftValue: Any, rightValue: Any)
        let infixTests: [TestPayload] = [
            ("5 + 5;", "+", 5, 5),
            ("5 - 5;", "-", 5, 5),
            ("5 * 5;", "*", 5, 5),
            ("5 / 5;", "/", 5, 5),
            ("5 > 5;", ">", 5, 5),
            ("5 < 5;", "<", 5, 5),
            ("5 == 5;", "==", 5, 5),
            ("5 != 5;", "!=", 5, 5),
            ("true == true", "==", true, true),
            ("true != false", "!=", true, false),
            ("false == false", "==", false, false)
        ]

        for test in infixTests {
            let program = REPL.createProgram(input: test.input)
            let expression = program.statements[0] as! ExpressionStatement
            testInfix(exp: expression.expression as! InfixExpression, left: test.leftValue, operator: test.operator, right: test.rightValue)
        }
    }

    func testOperatorPrecedenceParsing() throws {
        typealias TestPayload = (input: String, expect: String)
        let tests: [TestPayload] = [
            (
                "-a * b",
                "((-a) * b)"
            ),
            (
                "!-a",
                "(!(-a))"
            ),
            (
                "a + b + c",
                "((a + b) + c)"
            ),
            (
                "a * b * c",
                "((a * b) * c)"
            ),
            (
                "a * b / c",
                "((a * b) / c)"
            ),
            (
                "a + b * c + d / e - f",
                "(((a + (b * c)) + (d / e)) - f)"
            ),
            (
                "3 + 4; -5 * 5",
                "(3 + 4)((-5) * 5)"
            ),
            (
                "5 > 4 == 3 < 4",
                "((5 > 4) == (3 < 4))"
            ),
            (
                "5 > 4 != 3 < 4",
                "((5 > 4) != (3 < 4))"
            ),
            (
                "3 + 4 * 5 == 3 * 1 + 4 * 5",
                "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"
            ),
            (
                "true",
                "true"
            ),
            (
                "false",
                "false"
            ),
            (
                "3 > 5 == false",
                "((3 > 5) == false)"
            ),
            (
                "3 < 5 == true",
                "((3 < 5) == true)"
            ),
            (
                "1 + (2 + 3) + 4",
                "((1 + (2 + 3)) + 4)"
            ),
            (
                "(5 + 5) * 2",
                "((5 + 5) * 2)"
            ),
            (
                "2 / (5 + 5)",
                "(2 / (5 + 5))"
            ),
            (
                "-(5 + 5)",
                "(-(5 + 5))"
            ),
            (
                "!(true == true)",
                "(!(true == true))"
            ),
            (
                "a + add(b * c) + d",
                "((a + add((b * c))) + d)"
            ),
            (
                "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7* 8))",
                "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
            ),
            (
                "add(a + b + c * d / f + g)",
                "add((((a + b) + ((c * d) / f)) + g))"
            ),
            (
                "a * [1, 2, 3, 4][b * c] * d",
                "((a * ([1, 2, 3, 4][(b * c)])) * d)"
            ),
            (
                "add(a * b[2], b[1], 2 * [1, 2][1])",
                "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
            ),
        ]

        for test in tests {
            let program = REPL.createProgram(input: test.input)
            let actural = program.string().removeNewLine()
            XCTAssertEqual(test.expect, actural)
        }
    }

    func testIfExpression() throws {
        let input = "if (x < y) { x }"
        let program = REPL.createProgram(input: input)

        let expStmp = program.statements[0] as! ExpressionStatement
        let ifExp = expStmp.expression as! IfExpression
        testInfix(exp: ifExp.condition as! InfixExpression, left: "x", operator: "<", right: "y")

        XCTAssertEqual(ifExp.consequence.statements.count, 1)
        let consquenceExp = ifExp.consequence.statements[0] as! ExpressionStatement
        testIdentifier(exp: consquenceExp.expression as! IdentifierExp, value: "x")

        XCTAssertNil(ifExp.alternative)
    }

    func testIfElseExpression() throws {
        let input = "if (x < y) { x } else { y }"
        let program = REPL.createProgram(input: input)

        let expStmp = program.statements[0] as! ExpressionStatement
        let ifExp = expStmp.expression as! IfExpression
        testInfix(exp: ifExp.condition as! InfixExpression, left: "x", operator: "<", right: "y")

        XCTAssertEqual(ifExp.consequence.statements.count, 1)
        let consquenceExp = ifExp.consequence.statements[0] as! ExpressionStatement
        testIdentifier(exp: consquenceExp.expression as! IdentifierExp, value: "x")

        XCTAssertEqual(ifExp.alternative!.statements.count, 1)
        let alternative = ifExp.alternative!.statements[0] as! ExpressionStatement
        testIdentifier(exp: alternative.expression as! IdentifierExp, value: "y")
    }

    func testFunctionLiteralParsing() throws {
        let input = "fn(x, y) { x + y; }"
        let program = REPL.createProgram(input: input)

        XCTAssertEqual(program.statements.count, 1)

        let expStmt = program.statements[0] as! ExpressionStatement
        let funcLiteral = expStmt.expression as! FunctionLiteral
        XCTAssertEqual(funcLiteral.parameters.count, 2)
        testLiteral(exp: funcLiteral.parameters[0], expected: "x")
        testLiteral(exp: funcLiteral.parameters[1], expected: "y")

        let bodyExpStmt = funcLiteral.body.statements[0] as! ExpressionStatement
        testInfix(exp: bodyExpStmt.expression as! InfixExpression, left: "x", operator: "+", right: "y")
    }

    func testFunctionParameterParsing() throws {
        typealias TestPayload = (input: String, expectedParameters: [String])
        let tests: [TestPayload] = [
            ("fn() {}", []),
            ("fn(x) {}", ["x"]),
            ("fn(x, y, z) {}", ["x", "y", "z"])
        ]

        for test in tests {
            let program = REPL.createProgram(input: test.input)
            let expStmt = program.statements[0] as! ExpressionStatement
            let funcLiteral = expStmt.expression as! FunctionLiteral

            XCTAssertEqual(funcLiteral.parameters.count, test.expectedParameters.count)
            for i in 0..<test.expectedParameters.count {
                let expectValue = test.expectedParameters[i]
                testLiteral(exp: funcLiteral.parameters[i], expected: expectValue)
            }
        }
        
    }

    func testParsingLetStatementFunction() throws {
        typealias TestPayload = (input: String, variableName: String, expectedParameters: [String])
        let tests: [TestPayload] = [
            ("let a = fn() {}", "a", []),
            ("let a = fn(x) {}", "a", ["x"]),
            ("let a = fn(x, y, z) {}", "a", ["x", "y", "z"])
        ]

        for test in tests {
            let program = REPL.createProgram(input: test.input)
            let letStatement = program.statements[0] as! LetStatement

            XCTAssertEqual(letStatement.name.value, test.variableName)
            let funcLiteral = letStatement.value as! FunctionLiteral
            XCTAssertEqual(funcLiteral.parameters.count, test.expectedParameters.count)
            for i in 0..<test.expectedParameters.count {
                let expectValue = test.expectedParameters[i]
                testLiteral(exp: funcLiteral.parameters[i], expected: expectValue)
            }
        }
    }

    func testCallExpressionParsing() throws {
        let input = "add(1, 2 * 3, 4 + 5);"
        let program = REPL.createProgram(input: input)

        XCTAssertEqual(program.statements.count, 1)
        let expStmt = program.statements[0] as! ExpressionStatement
        let callExp = expStmt.expression as! CallExpression

        testIdentifier(exp: callExp.function as! IdentifierExp, value: "add")
        XCTAssertEqual(3, callExp.arguements.count)

        testLiteral(exp: callExp.arguements[0], expected: 1)
        testInfix(exp: callExp.arguements[1] as! InfixExpression, left: 2, operator: "*", right: 3)
        testInfix(exp: callExp.arguements[2] as! InfixExpression, left: 4, operator: "+", right: 5)
    }

    func testStringLiteralExpression() throws {
        let input = "\"hello world\""
        let program = REPL.createProgram(input: input)

        XCTAssertEqual(program.statements.count, 1)
        let stmt = program.statements[0] as! ExpressionStatement
        let stringLiteral = stmt.expression as! StringLiteral
        XCTAssertEqual(stringLiteral.value, "hello world")
    }

    func testParsingHashLiteralStringKeys() throws {
        let input = "{\"one\": 1, \"two\": 2, \"three\": \"3\", \"four\": true, \"five\": \"false\"}"
        let program = REPL.createProgram(input: input)

        let expStmt = program.statements[0] as! ExpressionStatement
        let hashLiteral = expStmt.expression as! HashLiteral
        let expects: [String: Any] = [
            "one": 1,
            "two": 2,
            "three": "3",
            "four": true,
            "five": "false"
        ]
        XCTAssertEqual(hashLiteral.pairs.count, expects.count)

        for pair in hashLiteral.pairs {
            let key = pair.key as! StringLiteral
            testLiteral(exp: pair.value, expected: expects[key.value]!)
        }
    }

    func testParsingEmptyHashLiteral() throws {
        let input = "{}"
        let program = REPL.createProgram(input: input)

        let expStmt = program.statements[0] as! ExpressionStatement
        let hashLiteral = expStmt.expression as! HashLiteral

        XCTAssertEqual(hashLiteral.pairs.count, 0)
    }

    func testParsingHashLiteralWithExpression() throws {
        let input = "{\"one\": 0 + 1, \"two\": 10 - 8, \"three\": 15 / 5}"
        typealias ExpectPayload = (key: String, left: Any, op: String, right: Any)
        let testeExpects: [ExpectPayload] = [
            (key: "one", left: 0, op: "+", right: 1),
            (key: "two", left: 10, op: "-", right: 8),
            (key: "three", left: 15, op: "/", right: 5)
        ]

        let program = REPL.createProgram(input: input)

        let expStmt = program.statements[0] as! ExpressionStatement
        let hashLiteral = expStmt.expression as! HashLiteral
        XCTAssertEqual(hashLiteral.pairs.count, testeExpects.count)

        for i in 0..<testeExpects.count {
            let expect = testeExpects[i]
            let pair = hashLiteral.pairs[i]

            XCTAssertEqual(pair.key.string(), expect.key)
            testInfix(exp: pair.value as! InfixExpression, left: expect.left, operator: expect.op, right: expect.right)
        }
    }

    func testParsingArrayLiteral() throws {
        let input = "[1, 2 * 2, 3 + 3]"
        let program = REPL.createProgram(input: input)

        let stmt = program.statements[0] as! ExpressionStatement
        let arrayLiteral = stmt.expression as! ArrayLiteral
        XCTAssertEqual(arrayLiteral.elements.count, 3)

        let integerLiteral = arrayLiteral.elements[0] as! IntegerLiteral
        XCTAssertEqual(integerLiteral.value, 1)
        testInfix(exp: arrayLiteral.elements[1] as! InfixExpression, left: 2, operator: "*", right: 2)
        testInfix(exp: arrayLiteral.elements[2] as! InfixExpression, left: 3, operator: "+", right: 3)
    }

    func testParsingIndexExpression() throws {
        let input = "myArray[1 + 1]"
        let program = REPL.createProgram(input: input)

        let stmt = program.statements[0] as! ExpressionStatement
        let indexLiteral = stmt.expression as! IndexExpression

        testIdentifier(exp: indexLiteral.left as! IdentifierExp, value: "myArray")
        testInfix(exp: indexLiteral.index as! InfixExpression, left: 1, operator: "+", right: 1)
    }

    func testParsingIndexExpressionWithArrayDeclare() throws {
        let input = "[1, 2 * 2, 3 + 3][1 + 1]"
        let program = REPL.createProgram(input: input)

        let stmt = program.statements[0] as! ExpressionStatement
        let indexLiteral = stmt.expression as! IndexExpression

        let arrayLiteral = indexLiteral.left as! ArrayLiteral
        XCTAssertEqual(arrayLiteral.elements.count, 3)
        let integerLiteral = arrayLiteral.elements[0] as! IntegerLiteral
        XCTAssertEqual(integerLiteral.value, 1)
        testInfix(exp: arrayLiteral.elements[1] as! InfixExpression, left: 2, operator: "*", right: 2)
        testInfix(exp: arrayLiteral.elements[2] as! InfixExpression, left: 3, operator: "+", right: 3)

        testInfix(exp: indexLiteral.index as! InfixExpression, left: 1, operator: "+", right: 1)
    }

    func testParsingIndexExpressionWithHashDeclare() throws {
        let input = "{\"one\": 0 + 1, \"two\": 10 - 8, \"three\": 15 / 5}[\"one\"]"
        let program = REPL.createProgram(input: input)

        let stmt = program.statements[0] as! ExpressionStatement
        let indexLiteral = stmt.expression as! IndexExpression

        let arrayLiteral = indexLiteral.left as! HashLiteral
        XCTAssertEqual(arrayLiteral.pairs.count, 3)

        testLiteral(exp: indexLiteral.index, expected: "one")
    }
}

extension ParserTest {
    private func verifyLetStatement(_ statement: Statement, _ name: String) {
        guard let letStatement = statement as? LetStatement else {
            assert(false, "Invalid statement")
        }

        assert(letStatement.tokenLiteral() == "let", "statement.tokenLiteral not 'let', got \(letStatement.tokenLiteral())")
        assert(letStatement.name.value == name, "statement.name.value not '\(name)', got \(letStatement.name.value)")
        assert(letStatement.name.tokenLiteral() == name, "statement.name.value not '\(name)', got \(letStatement.name.tokenLiteral())")
    }

    private func testInfix(exp: InfixExpression, left: Any, operator: String, right: Any) {
        testLiteral(exp: exp.left, expected: left)
        testLiteral(exp: exp.right, expected: right)
        XCTAssertEqual(exp.op, `operator`)
    }

    private func testLiteral(exp: Expression, expected: Any) {
        switch expected.self {
        case is Int:
            let literal = exp as! IntegerLiteral
            XCTAssertEqual(expected as! Int, literal.value)
        case is String:
            if let identifier = exp as? IdentifierExp {
                testIdentifier(exp: identifier, value: expected as! String)
            } else if let stringLiteral = exp as? StringLiteral {
                XCTAssertEqual(stringLiteral.value, expected as! String)
            } else {
                XCTFail()
            }
        case is Bool:
            let literal = exp as! BooleanLiteral
            XCTAssertEqual(expected as! Bool, literal.value)
        default:
            XCTFail()
        }
    }

    func testIdentifier(exp: IdentifierExp, value: String) {
        XCTAssertEqual(exp.value, value)
        XCTAssertEqual(exp.tokenLiteral(), value)
    }
}
