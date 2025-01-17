import Foundation

struct CameraInfo: Codable {
    struct Matrix4x4: Codable {
        var matrix: [Float]
    }

    struct Point: Codable {
        var x: Float
        var y: Float
    }

    struct Resolution: Codable {
        var x: Int
        var y: Int
    }

    var projectionMatrix: Matrix4x4
    var displayMatrix: Matrix4x4
    var focalLength: Point
    var principalPoint: Point
    var resolution: Resolution
}
