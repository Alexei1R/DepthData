//
//  OriginCalculator.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import ARKit

protocol OriginCalculator {
    func compute(_ frame: ARFrame) -> simd_float3?
}
