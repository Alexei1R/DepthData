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
