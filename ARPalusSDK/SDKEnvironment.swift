import Foundation
import FirebaseFirestore

public enum ArpalusSDK {
    public static func start(email: String, password: String , completion: @escaping () -> Void) {
        Task { @MainActor in
            do {
                let result = try await SDKEnvironment.shared.authentication.authenticate(email: email, password: password)
                print(result)
                let userSettings = try await SDKEnvironment.shared.settingsStore.getUserSettings()
                print("User settings: ", userSettings)
                let appSettings = try await SDKEnvironment.shared.settingsStore.getAppSettingsVersion()
                print("App settings: " ,appSettings)
                try await SDKEnvironment.shared.settingsStore.downloadAppSettings()
                try await SDKEnvironment.shared.settingsStore.getDeployments()
                try await SDKEnvironment.shared.settingsStore.downloadProjects()
            } catch {
                print("Error in starting sdk: ", error.localizedDescription)
            }
            completion()
        }
    }
}

struct SDKEnvironment {
    var localStorage: LocalStorage
    var authentication: Authentication
    var settingsStore: SettingsStore
    var imageSevice: ImageService

    static var shared: SDKEnvironment = {
        let localStorage: LocalStorage = LocalStorage()
        return SDKEnvironment(
            localStorage: localStorage,
            authentication: Authentication(),
            settingsStore: SettingsStore(localStorage: localStorage),
            imageSevice: ImageService(localStorage: localStorage)
        )
    }()
}
