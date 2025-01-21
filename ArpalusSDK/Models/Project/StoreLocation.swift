import Foundation

struct StoreLocation: Equatable, Codable {
    var baseType: Int
    var id: String
    var displayTitle: String
    var displayLine: String
    var address: String
    var storeId: String
    var gpsLatitude: Double
    var gpsLongitude: Double
    var taskIDs: [String]
    var tasks: [StoreTask]
    
}
