//
//  AppSettings.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

struct AppSettings: Equatable, Codable {
    let debug: Debug?
    let camera: Camera?
    let vision: Vision?
    let planogram: Planogram?
}

extension AppSettings {
    enum CodingKeys: String, CodingKey {
        case settingsData
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawSettings = try container.decode([String].self, forKey: .settingsData)
        let settings = rawSettings.compactMap { rawSetting in
            rawSetting.data(using: .utf8).flatMap { data in
                let setting = try? JSONDecoder().decode(AppSetting.self, from: data)
                return setting.map { AppSettingWrapper(appSetting: $0, rawData: data) }
            }
            
        }
        let decoder = JSONDecoder()
        var (debug, camera, vision, planogram): (Debug?, Camera?, Vision?, Planogram?)
        for setting in settings {
            switch setting.appSetting.systemName {
            case .debug:
                do {
                    debug = try decoder.decode(Debug.self, from: setting.rawData)
                } catch {
                    print(error)
                    throw error
                }

            case .camera:
                do {
                    camera = try decoder.decode(Camera.self, from: setting.rawData)
                } catch {
                    print(error)
                    throw error
                }
            case .vision:
                do {
                    vision = try decoder.decode(Vision.self, from: setting.rawData)
                } catch {
                    print(error)
                    throw error
                }
            case .planogram:
                do {
                    planogram = try decoder.decode(Planogram.self, from: setting.rawData)
                } catch {
                    print(error)
                    throw error
                }
            }
        }
        self.init(debug: debug, camera: camera, vision: vision, planogram: planogram)
    }

    func encode(to encoder: any Encoder) throws {
        let jsonEncoder = JSONEncoder()
        let debug = try debug.map { try jsonEncoder.encode($0) }
        let vision = try vision.map { try jsonEncoder.encode($0) }
        let camera = try camera.map { try jsonEncoder.encode($0) }
        let planogram = try planogram.map { try jsonEncoder.encode($0) }

        let settings = [debug, vision, camera, planogram]
            .compactMap { $0.flatMap { String(data: $0, encoding: .utf8) } }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settings, forKey: .settingsData)
    }
}

enum AppSettingName: String, Codable {
    case debug = "DebugSettings"
    case camera = "CameraCaptureSettings"
    case vision = "VisionInferenceSettings"
    case planogram = "PlanogramSettings"
}

struct AppSettingWrapper: Codable {
    let appSetting: AppSetting
    let rawData: Data
}

struct AppSetting: Codable {
    let version: Int
    let systemName: AppSettingName
    let tags: [String]
}
