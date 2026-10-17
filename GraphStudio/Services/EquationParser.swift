import Foundation

// MARK: - Tokens & AST

enum EqToken: Equatable {
    case number(Double)
    case identifier(String)
    case op(String)
    case lparen
    case rparen
}

indirect enum EqNode {
    case value(Double)
    case variable
    case unary(String, EqNode)
    case binary(String, EqNode, EqNode)
    case function(String, EqNode)
}

// MARK: - Recursive-descent parser

/// Parses expression tokens into an AST. Supports `+ - * / ^`, parentheses,
/// implicit multiplication (e.g. `2x`, `3(x + 1)`), unary minus, and function
/// calls.
final class ExprParser {
    private let tokens: [EqToken]
    private var index = 0

    init(_ tokens: [EqToken]) {
        self.tokens = tokens
    }

    private var peek: EqToken? {
        index < tokens.count ? tokens[index] : nil
    }

    private func advance() -> EqToken? {
        guard index < tokens.count else { return nil }
        let token = tokens[index]
        index += 1
        return token
    }

    func parse() throws -> EqNode {
        let node = try parseExpression()
        if peek != nil {
            throw EquationParsingError(message: "Unexpected token after expression")
        }
        return node
    }

    // expression := term (('+' | '-') term)*
    private func parseExpression() throws -> EqNode {
        var left = try parseTerm()
        while case let .op(op)? = peek, op == "+" || op == "-" {
            advance()
            let right = try parseTerm()
            left = .binary(op, left, right)
        }
        return left
    }

    // term := unary (('*' | '/') unary)*   plus implicit multiplication
    private func parseTerm() throws -> EqNode {
        var left = try parseUnary()
        while let token = peek {
            if case let .op(op) = token, op == "*" || op == "/" {
                advance()
                let right = try parseUnary()
                left = .binary(op, left, right)
            } else if Self.startsFactor(token) {
                // Implicit multiplication: 2x, 3( x + 1 ), 2sin(x)
                let right = try parseUnary()
                left = .binary("*", left, right)
            } else {
                break
            }
        }
        return left
    }

    private static func startsFactor(_ token: EqToken) -> Bool {
        switch token {
        case .number, .identifier, .lparen:
            return true
        default:
            return false
        }
    }

    // unary := ('-' | '+') unary | primary
    private func parseUnary() throws -> EqNode {
        if case let .op(op)? = peek, op == "-" || op == "+" {
            advance()
            let operand = try parseUnary()
            return op == "-" ? .unary("-", operand) : operand
        }
        return try parsePrimary()
    }

    // primary := number | identifier | identifier '(' expression ')' | '(' expression ')'
    private func parsePrimary() throws -> EqNode {
        guard let token = advance() else {
            throw EquationParsingError(message: "Unexpected end of expression")
        }
        switch token {
        case .number(let value):
            return .value(value)
        case .identifier(let name):
            if case .lparen? = peek {
                advance()
                let argument = try parseExpression()
                guard case .rparen? = advance() else {
                    throw EquationParsingError(message: "Expected ')' after function argument")
                }
                return .function(name, argument)
            }
            if let constant = ExprParser.constants[name] {
                return .value(constant)
            }
            return .variable
        case .lparen:
            let inner = try parseExpression()
            guard case .rparen? = advance() else {
                throw EquationParsingError(message: "Expected ')' to close group")
            }
            return inner
        default:
            throw EquationParsingError(message: "Unexpected token")
        }
    }

    static let constants: [String: Double] = [
        "pi": .pi,
        "tau": .pi * 2,
        "e": M_E,
    ]
}

// MARK: - Tokenizer

enum EqTokenizer {
    static func tokenize(_ input: String) throws -> [EqToken] {
        var tokens: [EqToken] = []
        let chars = Array(input)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace { i += 1; continue }

            if c.isNumber || (c == "." && i + 1 < chars.count && chars[i + 1].isNumber) {
                var raw = ""
                while i < chars.count, chars[i].isNumber || chars[i] == "." {
                    raw.append(chars[i])
                    i += 1
                }
                guard let value = Double(raw) else {
                    throw EquationParsingError(message: "Invalid number '\(raw)'")
                }
                tokens.append(.number(value))
                continue
            }

            if c.isLetter || c == "_" {
                var id = ""
                while i < chars.count,
                      chars[i].isLetter || chars[i].isNumber || chars[i] == "_" {
                    id.append(chars[i])
                    i += 1
                }
                tokens.append(.identifier(id.lowercased()))
                continue
            }

            switch c {
            case "+", "-", "*", "/", "^":
                tokens.append(.op(String(c)))
                i += 1
            case "(":
                tokens.append(.lparen)
                i += 1
            case ")":
                tokens.append(.rparen)
                i += 1
            case ",":
                i += 1 // single-argument functions; ignore separators
            default:
                throw EquationParsingError(message: "Unexpected character '\(c)'")
            }
        }
        return tokens
    }
}

// MARK: - Public API

/// Parses and evaluates `y = f(x)` style expressions.
///
/// Grammar (recursive descent / Pratt):
///   expression := term (('+' | '-') term)*
///   term       := unary (('*' | '/') unary | <implicit multiply>)*
///   unary      := ('-' | '+') unary | primary
///   primary    := number | identifier | identifier '(' expression ')' | '(' expression ')'
///
/// Supports constants (`pi`, `tau`, `e`) and functions (sin, cos, tan, asin,
/// acos, atan, sinh, cosh, tanh, exp, ln, log, sqrt, cbrt, abs, floor, ceil,
/// round, sign). Out-of-domain results yield `nil` so callers can plot gaps.
public struct EquationParser {
    public init() {}

    /// Parses an expression string into an `Equation`.
    public func parse(_ expression: String) throws -> Equation {
        let tokens = try EqTokenizer.tokenize(expression)
        let parser = ExprParser(tokens)
        let node = try parser.parse()
        return Equation(node: node)
    }

    /// Evaluates a parsed equation at `x`. Returns nil for out-of-domain inputs.
    public func evaluate(_ equation: Equation, at x: Double) -> Double? {
        evaluate(equation.node, x: x)
    }

    /// Samples an expression across a numeric range, dropping non-finite results.
    public func sample(
        _ expression: String,
        from minX: Double,
        to maxX: Double,
        step: Double
    ) throws -> [DataPoint] {
        let equation = try parse(expression)
        guard step > 0, minX <= maxX else { return [] }
        var points: [DataPoint] = []
        var x = minX
        while x <= maxX {
            if let y = evaluate(equation, at: x), y.isFinite {
                points.append(DataPoint(x: x, y: y))
            }
            x += step
        }
        return points
    }

    // MARK: Evaluation

    private func evaluate(_ node: EqNode, x: Double) -> Double? {
        switch node {
        case .value(let v):
            return v
        case .variable:
            return x
        case .unary(let op, let operand):
            guard let v = evaluate(operand, x: x) else { return nil }
            return op == "-" ? -v : v
        case .binary(let op, let lhs, let rhs):
            guard let l = evaluate(lhs, x: x), let r = evaluate(rhs, x: x) else { return nil }
            switch op {
            case "+": return l + r
            case "-": return l - r
            case "*": return l * r
            case "/": return r == 0 ? nil : l / r
            case "^": return pow(l, r)
            default: return nil
            }
        case .function(let name, let arg):
            guard let v = evaluate(arg, x: x) else { return nil }
            guard let fn = Self.functions[name] else { return nil }
            return fn(v)
        }
    }

    private static let functions: [String: (Double) -> Double?] = [
        "sin": { sin($0) },
        "cos": { cos($0) },
        "tan": { tan($0) },
        "asin": { abs($0) <= 1 ? asin($0) : nil },
        "acos": { abs($0) <= 1 ? acos($0) : nil },
        "atan": { atan($0) },
        "sinh": { sinh($0) },
        "cosh": { cosh($0) },
        "tanh": { tanh($0) },
        "exp": { exp($0) },
        "ln": { $0 > 0 ? log($0) : nil },
        "log": { $0 > 0 ? log10($0) : nil },
        "sqrt": { $0 >= 0 ? sqrt($0) : nil },
        "cbrt": { cbrt($0) },
        "abs": { abs($0) },
        "floor": { floor($0) },
        "ceil": { ceil($0) },
        "round": { round($0) },
        "sign": { $0 < 0 ? -1 : ($0 > 0 ? 1 : 0) },
    ]
}

/// An opaque parsed expression holding its abstract syntax tree.
public struct Equation {
    var node: EqNode
    init(node: EqNode) { self.node = node }
}

public struct EquationParsingError: Error, CustomStringConvertible {
    public let message: String
    public init(message: String) { self.message = message }
    public var description: String { message }
}
