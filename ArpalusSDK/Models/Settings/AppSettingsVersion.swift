import Foundation

struct ClientSettings: Codable, Equatable {
    let client: String
    let settingsName: String
    let version: Int
}
