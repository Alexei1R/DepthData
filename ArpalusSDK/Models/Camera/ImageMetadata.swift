import Foundation

struct ImageMetadata: Codable {
    var cameraInfo: String // to string ImageInfo
    var cameraTransformBefore: String // cameraPositionBefore^cameraRotationBefore %.6f
    var cameraTransformBeforeOriginal: String
    var cameraTransformAfter: String
    var originCaptureTransform: String
    var originDoneTransform: String
    var timestamp: String // 2025-01-16_14-07-48_507d2731e4e8 _miliGuidpart
    var time: Double
    var frameNumber: Int
    var imgCount: Int
    var saveButtonUsed: Bool
    var imageWidth: Int
    var imageHeight: Int
    var averageFps: Double
    var minFps: Double
    var velocity: Double
    var angularVelocity: Double
    var acceleration: Double
    var angularAcceleration: Double
    var frameResults: [FrameResult]
    var pointCloud: [String]
}

import simd

func buildCameraPoseString(position: simd_float3, rotation: simd_quatf) -> String {
    let comma = ","
    let separator = "^"

    return String(
        format: "%.6f,%.6f,%.6f^%.6f,%.6f,%.6f,%.6f",
        position.x,
        position.y,
        position.z,
        rotation.vector.x,
        rotation.vector.y,
        rotation.vector.z,
        rotation.vector.w
    )
}
