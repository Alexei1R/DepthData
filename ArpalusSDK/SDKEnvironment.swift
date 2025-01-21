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
                completion(.success(.loading(0.16)))
                try await SDKEnvironment.shared.settingsStore.getUserSettings()
                print("User settings: ", SDKEnvironment.shared.localStorage.userSettings)
                completion(.success(.loading(0.54)))
                try await SDKEnvironment.shared.settingsStore.getClientSettings()
                print("Client settings: ", SDKEnvironment.shared.localStorage.clientSettings)
                completion(.success(.loading(0.75)))
                try await SDKEnvironment.shared.settingsStore.getDeployments()
                print("Deployment settings: ", SDKEnvironment.shared.localStorage.deploymentSettings)
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
