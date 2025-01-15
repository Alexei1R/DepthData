import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

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

struct AppSettingsVersion: Codable, Equatable {
    let client: String
    let settingsName: String
    let version: Int
}

struct Deployment: Codable, Equatable {
    var client: String
    var deployment: String
    var lastDeployment: String
    var project: String
    var projectVersion: Int
    var thumbnailsBanksCount: Int
    var thumbnailsVersion: Int
    var tutorialSlidesCount: Int
    var tutorialVersion: Int
}

struct CVModelsBank: Codable, Equatable {
    var version: Int
    var cvModels: [CVModel]
}

struct CVModel: Codable, Equatable {
    var modelName: String
    var confThreshold: Double
    var inputResolution: Int
    var modelType: String
    var fileName: String
    var modelIndex: Int
    var fullModelNames: [String]
}

struct PlanogramBank: Codable, Equatable {
    var version: Int
    var planograms: [Planogram]
}

struct Planogram: Codable, Equatable {
    var planogramName: String
    var version: Int
    var index: Int
}
/*
 {
     "version": 16,
     "planograms": [
         {
             "planogramName": "Ч•Ч•Ч¤ЧњЧ™Чќ Ч•ЧўЧ•Ч’Ч™Ч•ЧЄ 165.5",
             "version": 16,
             "index": 0
         },
         {
             "planogramName": "Ч Ч§Ч Ч™Ч§Ч™Чќ 125.1-Ч Ч•Ч—Ч•ЧЄ",
             "v
 */

//struct Project {
//    var clientName: String
//    var projectName: String
//    var index:
//    var storesDefinitions:
//    var storeLocations:
//    var storeTasks:
//    var storeDisplays:
//    var questionSelections:
//    var questionOptions:
//    var clientDisplayName:
//    var slackChannelProduction:
//    var slackChannelProducts:
//    var localization:
//    var stores:
//}

/*
 "clientName": "Arpalus",
    "projectName": "NetanyaOffice",
    "index": -1,
    "storesDefinitions": [],
    "storeLocations": [],
    "storeTasks": [],
    "storeDisplays": [],
    "questionSelections": [],
    "questionOptions": [],
    "clientDisplayName": "Arpalus",
    "slackChannelProduction": "live_tag",
    "slackChannelProducts": "live_tag",
    "localization": "Hebrew",
    "stores": [
        {
            "storeName": "Ч•Ч•Ч¤ЧњЧ™Чќ Ч•ЧўЧ•Ч’Ч™Ч•ЧЄ",
            "localizedStoreName": "Ч•Ч•Ч¤ЧњЧ™Чќ Ч•ЧўЧ•Ч’Ч™Ч•ЧЄ",
            "id": "DorAlon-WaferAndCookies",
            "index": 0,
            "GPSLocationX": 0.0,
            "GPSLocationY": 0.0,
            "GPSLocationZ": 0.0,
            "fade": false,
            "address": "Israel",
            "storeId": "",
            "models": {
                "modelNames": [
                    "DorAlon-WaffersCookies-V1-categories",
                    "Waffers-Cookies"
                ]
            },
            "planogramNames": [
                "Ч•Ч•Ч¤ЧњЧ™Чќ Ч•ЧўЧ•Ч’Ч™Ч•ЧЄ 165.5"
            ]
        },
        {
            "storeName": "Ч—ЧЧ™Ч¤Ч™Чќ ЧћЧњЧ•Ч—Ч™Чќ",
            "localizedStoreName": "Ч—ЧЧ™Ч¤Ч™Чќ ЧћЧњЧ•Ч—Ч™Чќ",
            "id": "DorAlon-SaltySnacks",
            "index": 1,
            "GPSLocationX": 0.0,
            "GPSLocationY": 0.0,
            "GPSLocationZ": 0.0,
            "fade": false,
            "address": "Israel",
            "storeId": "",
            "models": {
                "modelNames": [
                    "DorAlon-SaltySnacks-V1-categories",
                    "Salty-Snacks"
                ]
            },
            "planogramNames": [
                "Ч—ЧЧ™Ч¤Ч™Чќ ЧћЧњЧ•Ч—Ч™Чќ 300.4"
            ]
        },
 */




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

    @Defaults("com.arpalus.sdk.deployments.settings")
    var deploymentSettings: Deployment? = nil

    private let storage = FirebaseStorage.Storage.sdk
    private let db = Firestore.sdk

    var email: String {
        Auth.sdk.currentUser?.email ?? ""
    }

    func getUserSettings() async throws -> UserSettings {
        let userSettings = try await db.collection("Users").document("\(email)").getDocument(as: UserSettings.self)
        self.userSettings = userSettings
        print(userSettings)
        return userSettings
    }

    func getAppSettingsVersion() async throws -> AppSettingsVersion {
        guard let userSettings else { throw SDKError.missingUserSettings }
        let settings = try await db.collection("Settings").document("\(userSettings.client)_\(userSettings.settings)").getDocument(as: AppSettingsVersion.self)

        if appSettings?.version != settings.version {
            appSettings = settings
        }

        return settings
    }

    func downloadAppSettings() async throws {
        guard let userSettings else { throw SDKError.missingUserSettings }
        try await storage.reference(
            withPath: "\(userSettings.client)/Settings/\(userSettings.settings).settings"
        ).writeAsync(
            toFile: Disk(userId: userSettings.id).appSettingsURL,
            onProgress: { progress in
                print(progress)
            }
        )
    }

    func getDeployments() async throws {
        guard let userSettings else { throw SDKError.missingUserSettings}
        let deployment = try await db.collection("Deployments").document("\(userSettings.client)_\(userSettings.project)_\(userSettings.deployment)").getDocument(as: Deployment.self)
        if self.deploymentSettings?.projectVersion != deployment.projectVersion {
            self.deploymentSettings = deployment
            print("deployment: ", deployment)
        }
    }

    func downloadProjects() async throws {
        guard let deploymentSettings else { return }
        guard let userSettings else { return }
        let decoder = JSONDecoder()
        let cvModelsRef = try await storage.reference(
            withPath: "\(deploymentSettings.client)/Projects/\(deploymentSettings.project)/\(deploymentSettings.deployment)/CVModelBank.json"
        ).writeAsync(toFile: Disk(userId: userSettings.id).appCVModelsBank) { progress in
            print(progress)
        }.absoluteURL
        let planogramaBankRef = try await storage.reference(
            withPath: "\(deploymentSettings.client)/Projects/\(deploymentSettings.project)/\(deploymentSettings.deployment)/PlanogramBank.json"
        ).writeAsync(toFile: Disk(userId: userSettings.id).appPlanogramBank) { progress in
            print(progress)
        }.absoluteURL
        let project = try await storage.reference(
            withPath: "\(deploymentSettings.client)/Projects/\(deploymentSettings.project)/\(deploymentSettings.deployment)/Project.json"
        ).writeAsync(toFile: Disk(userId: userSettings.id).appProject) { progress in
            print(progress)
        }.absoluteURL

        if let modelsData = try? Data(contentsOf: cvModelsRef) {
            let cvModelsBank = try decoder.decode(CVModelsBank.self, from: modelsData)
        }
        if let planogramaData = try? Data(contentsOf: cvModelsRef) {
            print(planogramaData)

            let planogramBank = try decoder.decode(PlanogramBank.self, from: planogramaData)
            print(planogramaData)
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
