import Foundation

struct ClassResult: Codable {
    var name: String
    var categoryName: String
    var modelName: String
    var tagId: Int
    var id: Int
    var confidence: Double
    var confidenceProduct: Double
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var isOutlierDetection: Bool
    var frameNumber: Int
    var processed: Bool
}
