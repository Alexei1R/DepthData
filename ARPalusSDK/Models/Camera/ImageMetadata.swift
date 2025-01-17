import Foundation

struct ImageMetadata: Codable {
    var cameraInfo: CameraInfo
    var timestamp: String
    var imageWidth: Int
    var imageHeight: Int
    var frameNumber: Int
}
