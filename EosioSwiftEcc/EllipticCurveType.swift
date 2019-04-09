//
//  EllipticCurveType.swift
//  EosioSwiftEcc

//  Created by Todd Bowden on 3/27/19
//  Copyright (c) 2018-2019 block.one
//

import Foundation
import EosioSwift

/// EllipticCurveType enum defines the two ECC's currently supported
public enum EllipticCurveType: String {
    case r1 = "R1" // swiftlint:disable:this identifier_name
    case k1 = "K1" // swiftlint:disable:this identifier_name

    /**
     Init an EllipticCurveType
     
     - Parameters:
     - curve: A String defining the curve type of the enum
     
     */
    public init(_ curve: String) throws {
        switch curve.uppercased() {
        case "R1":
            self = .r1
        case "K1":
            self = .k1
        default:
            throw EosioError(.keyManagementError, reason: "\(curve) curve is not supported")
        }
    }
}
