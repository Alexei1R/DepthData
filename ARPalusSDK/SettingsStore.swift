import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct UserSettings: Codable, Equatable {
    let automation: Int
    let client: String
    let dashboardAccess: Bool
    let dashboardAuthLevel: String
    let dashboardName: String
    let deployment: String
    let email: String
    let id: String
    let postOnSlack: Bool
    let project: String
    let realTime: Bool
    let rlsRole: String
    let settings: String
    let task: String
    let username: String
}

struct AppSettingsVersion: Codable, Equatable {
    let client: String
    let settingsName: String
    let version: Int
}

enum SDKError: Error {
    case missingUserSettings
    case missingRemoteSettings
    case missingContent
    case unauthorized
}

final class SettingsStore {
    @Defaults("com.arpalus.sdk.user.settings")
    var userSettings: UserSettings? = nil

    @Defaults("com.arpalus.sdk.app.settings")
    var appSettings: AppSettingsVersion? = nil

    private let storage = FirebaseStorage.Storage.sdk
    private let db = Firestore.sdk

    var email: String {
        Auth.sdk.currentUser?.email ?? ""
    }

    func getUserSettings() async throws -> UserSettings {
        let userSettings = try await db.document("Users/\(email)").getDocument(as: UserSettings.self)
        self.userSettings = userSettings

        return userSettings
    }

    func getAppSettingsVersion() async throws -> AppSettingsVersion {
        guard let userSettings else { throw SDKError.missingUserSettings }
        let settings = try await db.document("Settings/\(userSettings.client)_\(userSettings.settings)").getDocument(as: AppSettingsVersion.self)

        if appSettings?.version != settings.version {
            appSettings = settings
        }

        return settings
    }

    func downloadAppSettings() async throws {
        guard let userSettings else { throw SDKError.missingUserSettings }
        try await storage.reference(
            withPath: "\(userSettings.client)/Settings/\(userSettings.settings)"
        ).writeAsync(
            toFile: Disk(userId: userSettings.id).appSettingsURL,
            onProgress: { progress in
                print(progress)
            }
        )
    }
}


struct Disk {
    let userId: String

    let localRoot = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    var localRootForUser: URL {
        let path = localRoot.appendingPathComponent(userId, conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            try! FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }

        return path
    }

    var appSettingsURL: URL {
        localRootForUser.appendingPathComponent("settings", conformingTo: .json)
    }
}
