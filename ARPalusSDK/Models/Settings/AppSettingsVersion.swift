import Foundation

struct AppSettingsVersion: Codable, Equatable {
    let client: String
    let settingsName: String
    let version: Int
}
