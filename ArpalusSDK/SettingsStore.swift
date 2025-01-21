import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

enum SDKError: Error {
    case missingUserSettings
    case missingRemoteSettings
    case missingContent
    case unauthorized
}

final class SettingsStore {

    private let localStorage: LocalStorage
    private let storage = FirebaseStorage.Storage.sdk
    private let db = Firestore.sdk

    var email: String {
        Auth.sdk.currentUser?.email ?? ""
    }

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

    func getUserSettings() async throws  {
        let userSettings = try await db.collection("Users").document("\(email)").getDocument(as: UserSettings.self)
        localStorage.userSettings = userSettings
    }

    func getClientSettings() async throws {
        guard let userSettings = localStorage.userSettings else { throw SDKError.missingUserSettings }
        let settings = try await db.collection("Settings")
            .document("\(userSettings.client)_\(userSettings.settings)")
            .getDocument(as: ClientSettings.self)

        if localStorage.clientSettings?.version != settings.version {
            localStorage.clientSettings = settings
            try await downloadAppSettings()
        }
    }

    func downloadAppSettings() async throws {
        guard let userSettings = localStorage.userSettings else { throw SDKError.missingUserSettings }
        let url = try await storage.reference(
            withPath: "\(userSettings.client)/Settings/\(userSettings.settings).settings"
        ).writeAsync(
            toFile: Disk(userId: userSettings.id).appSettingsURL,
            onProgress: { progress in
//                print("🔵", progress)
            }
        )
        let data = try Data(contentsOf: url)
        localStorage.appSettings = try JSONDecoder().decode(AppSettings.self, from: data)
    }

    func getDeployments() async throws {
        guard let userSettings = localStorage.userSettings else { throw SDKError.missingUserSettings}
        let deployment = try await db.collection("Deployments").document("\(userSettings.client)_\(userSettings.project)_\(userSettings.deployment)").getDocument(as: Deployment.self)
        if localStorage.deploymentSettings?.projectVersion != deployment.projectVersion {
            localStorage.deploymentSettings = deployment
            try await downloadProjects()
        }
    }

    func downloadProjects() async throws {
        guard let deploymentSettings = localStorage.deploymentSettings else { return }
        guard let userSettings = localStorage.userSettings else { return }
        let decoder = JSONDecoder()
        let cvModelsRef = try await storage.reference(
            withPath: "\(deploymentSettings.client)/Projects/\(deploymentSettings.project)/\(deploymentSettings.deployment)/CVModelBank.json"
        ).writeAsync(toFile: Disk(userId: userSettings.id).appCVModelsBank) { progress in
//            print("🔵", progress)
        }.absoluteURL
        let planogramaBankRef = try await storage.reference(
            withPath: "\(deploymentSettings.client)/Projects/\(deploymentSettings.project)/\(deploymentSettings.deployment)/PlanogramBank.json"
        ).writeAsync(toFile: Disk(userId: userSettings.id).appPlanogramBank) { progress in
//            print("🔵", progress)
        }.absoluteURL
        let projectRef = try await storage.reference(
            withPath: "\(deploymentSettings.client)/Projects/\(deploymentSettings.project)/\(deploymentSettings.deployment)/Project.json"
        ).writeAsync(toFile: Disk(userId: userSettings.id).appProject) { progress in
//            print("🔵",progress)
        }.absoluteURL

        if let modelsData = try? Data(contentsOf: cvModelsRef) {
            let cvModelsBank = try decoder.decode(CVModelsBank.self, from: modelsData)
            localStorage.cvModelsBank = cvModelsBank
        }
        if let planogramaData = try? Data(contentsOf: planogramaBankRef) {
            let planogramBank = try decoder.decode(PlanogramBank.self, from: planogramaData)
            localStorage.planogramBank = planogramBank
        }
        if let projectData = try? Data(contentsOf: projectRef) {
            let project = try decoder.decode(Project.self, from: projectData)
            localStorage.project = project
        }

    }
    //
    //    func downloaCVModels() async throws {
    //        guard let userSettings else { throw SDKError.missingUserSettings }
    //        try await storage.reference(
    //            withPath: "CVModels/"
    //        )
    //    }
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

    var appCVModelsBank: URL {
        localRootForUser.appendingPathComponent("CVModelBank", conformingTo: .json)
    }
    var appPlanogramBank: URL {
        localRootForUser.appendingPathComponent("PlanogramBank", conformingTo: .json)
    }
    var appProject: URL {
        localRootForUser.appendingPathComponent("Project", conformingTo: .json)
    }
}
