import Foundation

struct StoreDefinition: Equatable, Codable {
    var baseType: Int
    var id: String
    var displayTitle: String
    var displayLine: String
    var root: Bool
    var locations: [StoreLocation]
    var nextIDs: [String]
}
