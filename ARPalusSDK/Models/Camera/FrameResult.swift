import Foundation

struct FrameResult: Codable {
    var categoriesProcessed: Bool
    var specificProcessed: [String]
    var shelfProcessed: Bool
    var cameraAngleValid: Bool
    var processingTime: Double
    var categoriesResultsProcessed: Bool
    var shelfResultsProcessed: Bool
    var categories: [ClassResult]
    var specific: [ClassResult]
    var shelves: [ClassResult]
    var categoryModelResults:[ClassResult]
    var specificModelResults:[ClassResult]
    var shelfModelResults:[ClassResult]
}

