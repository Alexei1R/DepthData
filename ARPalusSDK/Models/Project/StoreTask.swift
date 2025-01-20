import Foundation

struct StoreTask: Codable, Equatable {
    var baseType: Int
    var id: String
    var displayTitle: String
    var displayLine: String
    var nextIDs: [String]
}
