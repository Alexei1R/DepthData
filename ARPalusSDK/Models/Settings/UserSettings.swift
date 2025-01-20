import Foundation

struct UserSettings: Codable, Equatable {
    let automation: Int
    let client: String
    let dashboard_access: Bool
    let dashboard_auth_level: String?
    let dashboard_name: String?
    let deployment: String
    let email: String
    let id: String
    let postOnSlack: Bool
    let project: String
    let real_time: Bool
    let rls_role: String?
    let settings: String
    let task: String
    let username: String
}

