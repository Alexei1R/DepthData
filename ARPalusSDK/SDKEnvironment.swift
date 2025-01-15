import Foundation
import FirebaseFirestore

public enum ArpalusSDK {
    public static func start(email: String, password: String ) {
        Task { @MainActor in
            do {
                let result = try await SDKEnvironment.shared.authentication.authenticate(email: email, password: password)
                print(result)
//                let doc = try await Firestore.sdk.collection("Users").document(email).getDocument(as: UserSettings.self)
//                print(doc)
                let userSettings = try await SDKEnvironment.shared.settingsStore.getUserSettings()
                print("User settings: ", userSettings)
                let appSettings = try await SDKEnvironment.shared.settingsStore.getAppSettingsVersion()
                print("App settings: " ,appSettings)
                try await SDKEnvironment.shared.settingsStore.downloadAppSettings()
                try await SDKEnvironment.shared.settingsStore.getDeployments()
                try await SDKEnvironment.shared.settingsStore.downloadProjects()
            } catch {
                print("Error in starting sdk", error.localizedDescription)
            }
        }
    }
//    public static func getViewController() -> ScanningViewController {
//
//    }
}

struct SDKEnvironment {
    var authentication: Authentication
    var settingsStore: SettingsStore

    static var shared: SDKEnvironment = {
        SDKEnvironment(
            authentication: Authentication(),
            settingsStore: SettingsStore()
        )
    }()
}
