import Foundation
import FirebaseFirestore

public enum Arpalus {
    public enum Status {
        case loading(Double)
        case initialized
    }
    public static func start(email: String, password: String , completion: @escaping (Result<Status, Error>) -> Void) {
        Task { @MainActor in
            do {
                let result = try await SDKEnvironment.shared.authentication.authenticate(email: email, password: password)
                print(result)
                completion(.success(.loading(0.16)))
                let userSettings = try await SDKEnvironment.shared.settingsStore.getUserSettings()
                print("User settings: ", userSettings)
                completion(.success(.loading(0.33)))
                let previousClientSettingsVersion = SDKEnvironment.shared.localStorage.clientSettings?.version
                completion(.success(.loading(0.5)))
                let clientSettings = try await SDKEnvironment.shared.settingsStore.getClientSettings()
                print("Client settings: ", clientSettings)
//                if previousClientSettingsVersion != clientSettings.version {
                    try await SDKEnvironment.shared.settingsStore.downloadAppSettings()
//                }
                completion(.success(.loading(0.66)))
                try await SDKEnvironment.shared.settingsStore.getDeployments()
                completion(.success(.loading(0.83)))
                try await SDKEnvironment.shared.settingsStore.downloadProjects()
                completion(.success(.initialized))
            } catch {
                print("Error in starting sdk: ", error.localizedDescription)
                completion(.failure(error))
            }
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
