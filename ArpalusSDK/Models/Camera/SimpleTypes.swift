import Foundation

struct Matrix4x4: Codable {
    var matrix: [Float]
}

struct Point: Codable {
    var x: Double
    var y: Double
}

struct Resolution: Codable {
    var x: Int
    var y: Int
}

struct RGBA: Codable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
}

struct Vector: Codable {
    var x: Double
    var y: Double
    var z: Double
}

struct Quaternion: Codable {
    var x: Double
    var y: Double
    var z: Double
    var w: Double
}

import simd

extension simd_float4x4 {
    var codableMatrix: Matrix4x4 {
        .init(matrix: columns.0.values + columns.1.values + columns.2.values + columns.3.values)
    }
}

extension simd_float4 {
    var values: [Float] { [x, y, z, w] }
}
