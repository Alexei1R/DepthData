import Foundation

struct StoreDisplay: Equatable, Codable {
    var baseType: Int
    var id: String
    var displayTitle: String
    var displayLine: String
    var maximum: Int
    var planogramNames: [String]
    var modelNames: [String]
}
