//
//  EosioSwiftRecoverKeysNoOpenSSLTests.swift
//  EosioSwiftEccTests

//  Created by Steve McCoole on 5/29/20
//  Copyright (c) 2017-2020 block.one and its contributors. All rights reserved.
//

import XCTest
import BigInt
import EosioSwift
@testable import EosioSwiftEcc

class EosioSwiftRecoverKeysNoOpenSSLTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRecoverPublicK1KeyFromPrivate() throws {
        let publicKeyHex = "04257784a3d0aceef73ea365ce01febaec1b671b971b9c9feb3f4901e7b773bd4366c7451a736e2921b3dfeefc2855e984d287d58a0dfb995045f339a0e8a2fd7a"
        let privateKeyHex = "c057a9462bc219abd32c6ca5c656cc8226555684d1ee8d53124da40330f656c1"

        let point = Secp256k1.G * Number(hexString: privateKeyHex)!
        let pointHex = "04" + point.x.asHexStringLength64(uppercased: false) + point.y.asHexStringLength64(uppercased: false)
        XCTAssertEqual(pointHex, publicKeyHex, "Public key hex did not match expected value.")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

// swiftlint:disable identifier_name
// swiftlint:disable shorthand_operator
public struct Secp256r1: EllipticCurve {

    /// `2^256 - 2^224 + 2^192 + 2^96 - 1` <=> `2^224 * (2^32 − 1) + 2^192 +2^96 − 1`
    public static let P = Number(hexString: "0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF")!

    public static let a = Number(hexString: "0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC")!
    public static let b = Number(hexString: "0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B")!
    public static let G = Point(
        x: Number(hexString: "0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296")!,
        y: Number(hexString: "0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5")!
    )

    public static let N = Number(hexString: "0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551")!
    public static let h = Number(1)
    public static let name = CurveName.secp256r1
}

public struct Secp256k1: EllipticCurve {

    /// `2^256 −2^32 −2^9 −2^8 −2^7 −2^6 −2^4 − 1` <=> `2^256 - 2^32 - 977`
    public static let P = Number(hexString: "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F")!

    public static let a = Number(0)
    public static let b = Number(7)
    public static let G = Point(
        x: Number(hexString: "0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")!,
        y: Number(hexString: "0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8")!
    )

    public static let N = Number(hexString: "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")!
    public static let h = Number(1)
    public static let name = CurveName.secp256k1
}

public struct AffinePoint<CurveType: EllipticCurve>: EllipticCurvePoint {
    public typealias Curve = CurveType
    public let x: Number
    public let y: Number

    public init(x: Number, y: Number) {
        precondition(x >= 0, "Coordinates should have non negative values, x was negative: `\(x)`")
        precondition(y >= 0, "Coordinates should have non negative values, y was negative: `\(y)`")
        self.x = x
        self.y = y
    }
}

// EllipticCurvePoint
public extension AffinePoint {

    /// From: https://github.com/sipa/bips/blob/bip-schnorr/bip-schnorr.mediawiki#specification
    /// "Addition of points refers to the usual elliptic curve group operation."
    /// reference: https://en.wikipedia.org/wiki/Elliptic_curve#The_group_law
    static func addition(_ p1: AffinePoint?, _ p2: AffinePoint?) -> AffinePoint? {
        return addition_v2(p1, p2)
    }

    static func addition_v1(_ p1: AffinePoint?, _ p2: AffinePoint?) -> AffinePoint? {
        guard let p1 = p1 else { return p2 }
        guard let p2 = p2 else { return p1 }

        if p1.x == p2.x && p1.y != p2.y {
            return nil
        }

        let P = Curve.P

        let λ = modP {
            if p1 == p2 {
                return (3 * (p1.x * p1.x) + Curve.a) * (2 * p1.y).power(P - 2, modulus: P)
            } else {
                return (p2.y - p1.y) * (p2.x - p1.x).power(P - 2, modulus: P)
            }
        }
        let x3 = modP { λ * λ - p1.x - p2.x }
        let y3 =  modP { λ * (p1.x - x3) - p1.y }

        return AffinePoint(x: x3, y: y3)
    }

    static func addition_v2(_ p1: AffinePoint?, _ p2: AffinePoint?) -> AffinePoint? {
        guard let p1 = p1 else { return p2 }
        guard let p2 = p2 else { return p1 }

        if p1.x == p2.x && p1.y != p2.y {
            return nil
        }

        if p1 == p2 {
            /// or `p2`, irrelevant since they equal each other
            return doublePoint(p1)
        } else {
            return addPoint(p1, to: p2)
        }
    }

    private static func addPoint(_ p1: AffinePoint, to p2: AffinePoint) -> AffinePoint {
        precondition(p1 != p2)
        let λ = modInverseP(p2.y - p1.y, p2.x - p1.x)
        let x3 = modP { λ * λ - p1.x - p2.x }
        let y3 = modP { λ * (p1.x - x3) - p1.y }
        return AffinePoint(x: x3, y: y3)
    }

    private static func doublePoint(_ p: AffinePoint) -> AffinePoint {
        let λ = modInverseP(3 * (p.x * p.x) + Curve.a, 2 * p.y)

        let x3 = modP { λ * λ - 2 * p.x }
        let y3 = modP { λ * (p.x - x3) - p.y }

        return AffinePoint(x: x3, y: y3)
    }

    /// From: https://github.com/sipa/bips/blob/bip-schnorr/bip-schnorr.mediawiki#specification
    /// "Multiplication of an integer and a point refers to the repeated application of the group operation."
    /// reference: https://en.wikipedia.org/wiki/Elliptic_curve_point_multiplication
    static func * (point: AffinePoint, number: Number) -> AffinePoint {
        var P: AffinePoint? = point
        let n = number
        var r: AffinePoint!
        for i in 0..<n.magnitude.bitWidth {
            if n.magnitude[bitAt: i] {
                r = addition(r, P)
            }
            P = addition(P, P)
        }
        return r
    }

}

public protocol EllipticCurvePoint: Equatable, CustomStringConvertible {
    associatedtype Curve: EllipticCurve
    var x: Number { get }
    var y: Number { get }

    init(x: Number, y: Number)

    static func addition(_ p1: Self?, _ p2: Self?) -> Self?

    static func * (point: Self, number: Number) -> Self
}

public extension EllipticCurvePoint {
    static func modP(_ expression: @escaping () -> Number) -> Number {
        return Curve.modP(expression)
    }

    func modP(expression: @escaping () -> Number) -> Number {
        return Self.modP(expression)
    }

    static func modInverseP(_ v: Number, _ w: Number) -> Number {
        return Curve.modInverseP(v, w)
    }

    func modInverseP(_ v: Number, _ w: Number) -> Number {
        return Self.modInverseP(v, w)
    }

    static func modInverseN(_ v: Number, _ w: Number) -> Number {
        return Curve.modInverseN(v, w)
    }

    func modInverseN(_ v: Number, _ w: Number) -> Number {
        return Self.modInverseN(v, w)
    }

    var description: String {
        return "(x: \(x.asHexString()), y: \(x.asHexString())"
    }

    func isOnCurve() -> Bool {
        let a = Curve.a
        let b = Curve.b
        let x = self.x
        let y = self.y

        let y² = modP { y * y }
        let x³ = modP { x * x * x }
        let ax = modP { a * x }

        return modP { y² - x³ - ax } == b
    }
}

public enum CurveName {
    case secp256k1, secp256r1
}

public protocol EllipticCurve {
    typealias Point = AffinePoint<Self>
    static var P: Number { get }
    static var a: Number { get }
    static var b: Number { get }
    static var G: Point { get }
    static var N: Number { get }
    static var h: Number { get }
    static var name: CurveName { get }
}

public extension EllipticCurve {
    static var order: Number {
        return N
    }
}

public extension EllipticCurve {
    static func addition(_ p1: Point?, _ p2: Point?) -> Point? {
        return Point.addition(p1, p2)
    }
}

private extension EllipticCurve {
    var P: Number { return Self.P }
    var a: Number { return Self.a }
    var b: Number { return Self.b }
    var G: Point { return Self.G }
    var N: Number { return Self.N }
    var h: Number { return Self.h }
}

extension EllipticCurve {
    static func modP(_ expression: () -> Number) -> Number {
        return mod(expression(), modulus: P)
    }

    static func modN(_ expression: () -> Number) -> Number {
        return mod(expression(), modulus: N)
    }

    static func modInverseP(_ v: Number, _ w: Number) -> Number {
        return modularInverse(v, w, mod: P)
    }

    static func modInverseN(_ v: Number, _ w: Number) -> Number {
        return modularInverse(v, w, mod: N)
    }
}

public typealias Number = BigInt

public extension Number {

    init(sign: Number.Sign = .plus, _ words: [Number.Word]) {
        let magnitude = Number.Magnitude(words: words)
        self.init(sign: sign, magnitude: magnitude)
    }

    init(sign: Number.Sign = .plus, data: Data) {
        self.init(sign: sign, Number.Magnitude(data))
    }

    init(sign: Number.Sign = .plus, _ magnitude: Number.Magnitude) {
        self.init(sign: sign, magnitude: magnitude)
    }

    init?(hexString: String) {
        var hexString = hexString
        if hexString.starts(with: "0x") {
            hexString = String(hexString.dropFirst(2))
        }
        self.init(hexString, radix: 16)
    }

    init?(decimalString: String) {
        self.init(decimalString, radix: 10)
    }

    var isEven: Bool {
        guard self.sign == .plus else { fatalError("what to do when negative?") }
        return magnitude[bitAt: 0] == false
    }

    func asHexString(uppercased: Bool = true) -> String {
        return toString(uppercased: uppercased, radix: 16)
    }

    func asDecimalString(uppercased: Bool = true) -> String {
        return toString(uppercased: uppercased, radix: 10)
    }

    func toString(uppercased: Bool = true, radix: Int) -> String {
        let stringRepresentation = String(self, radix: radix)
        guard uppercased else { return stringRepresentation }
        return stringRepresentation.uppercased()
    }

    func asHexStringLength64(uppercased: Bool = true) -> String {
        var hexString = toString(uppercased: uppercased, radix: 16)
        while hexString.count < 64 {
            hexString = "0\(hexString)"
        }
        return hexString
    }

    func as256bitLongData() -> Data? {
        return try? Data(hex: asHexStringLength64())
    }

    func asTrimmedData() -> Data {
        return self.magnitude.serialize()
    }
}

extension Data {
    func toNumber() -> Number {
        return Number(data: self)
    }
}

public func mod(_ number: Number, modulus: Number) -> Number {
    var mod = number % modulus
    if mod < 0 {
        mod = mod + modulus
    }
    guard mod >= 0 else { fatalError("NEGATIVE VALUE") }
    return mod
}

func modularInverse<T: BinaryInteger>(_ x: T, _ y: T, mod: T) -> T {
    let x = x > 0 ? x : x + mod
    let y = y > 0 ? y : y + mod

    let inverse = extendedEuclideanAlgorithm(z: y, a: mod)

    var result = (inverse * x) % mod

    let zero: T = 0
    if result < zero {
        result = result + mod
    }

    return result
}

private func division<T: BinaryInteger>(_ a: T, _ b: T) -> (quotient: T, remainder: T) {
    return (a / b, a % b)
}

/// https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
private func extendedEuclideanAlgorithm<T: BinaryInteger>(z: T, a: T) -> T {
    var i = a
    var j = z
    var y1: T = 1
    var y2: T = 0

    let zero: T = 0
    while j > zero {
        let (quotient, remainder) = division(i, j)

        let y = y2 - y1 * quotient

        i = j
        j = remainder
        y2 = y1
        y1 = y
    }

    return y2 % a
}
