import Foundation

struct CameraInfo: Codable {
    
    struct AmbientSphericalHarmonics: Codable {
        var coefficients: [[Double]]
    }
    
    var projectionMatrix: Matrix4x4
    var displayMatrix: Matrix4x4
    var exposureDuration: Double
    var exposureOffset: Double

    var focalLength: Point
    var principalPoint: Point
    var resolution: Resolution

    var averageBrightness: Double
    var averageColorTemperature: Double
    var averageIntensityInLumens: Double
    var mainLightIntensityLumens: Double
    var averageMainLightBrightness: Double
    var colorCorrection: RGBA
    var mainLightColor: RGBA
    var mainLightDirection: Vector
    var ambientSphericalHarmonics: AmbientSphericalHarmonics

}
