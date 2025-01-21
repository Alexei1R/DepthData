struct CVModel: Codable, Equatable {
    var modelName: String
    var confThreshold: Double
    var inputResolution: Int
    var modelType: String
    var fileName: String
    var modelIndex: Int
    var fullModelNames: [String]
}

