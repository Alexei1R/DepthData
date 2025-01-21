//
//  AppSettings.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

struct AppSettings: Equatable, Codable {
    let debug: Debug
    let camera: Camera
    let vision: Vision
    let planogram: Planogram
    let text: TextSettings
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
        var (debug, camera, vision, planogram, text) = (Debug(), Camera(), Vision(), Planogram(), TextSettings())
        for setting in settings {
            switch setting.appSetting.systemName {
            case .debug:
                do {
                    debug = try customDecode(data: setting.rawData, defaultValue: debug)
                } catch {
                    print(error)
                    throw error
                }

            case .camera:
                do {
                    camera = try customDecode(data: setting.rawData, defaultValue: camera)
                } catch {
                    print(error)
                    throw error
                }
            case .vision:
                do {
                    vision = try customDecode(data: setting.rawData, defaultValue: vision)
                } catch {
                    print(error)
                    throw error
                }
            case .planogram:
                do {
                    planogram = try customDecode(data: setting.rawData, defaultValue: planogram)
                } catch {
                    print(error)
                    throw error
                }
            case .text:
                do {
                    text =  try customDecode(data: setting.rawData, defaultValue: text)
                } catch {
                    print(error)
                    throw error
                }
            }
        }
        self.init(debug: debug, camera: camera, vision: vision, planogram: planogram, text: text)
    }

    func encode(to encoder: any Encoder) throws {
        let jsonEncoder = JSONEncoder()
        let debug = try jsonEncoder.encode(debug)
        let vision = try jsonEncoder.encode(vision)
        let camera = try jsonEncoder.encode(camera)
        let planogram = try jsonEncoder.encode(planogram)
        let text = try jsonEncoder.encode(text)

        let settings = [debug, vision, camera, planogram, text]
            .compactMap { String(data: $0, encoding: .utf8) }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(settings, forKey: .settingsData)
    }
}

enum AppSettingName: String, Codable {
    case debug = "DebugSettings"
    case camera = "CameraCaptureSettings"
    case vision = "VisionInferenceSettings"
    case planogram = "PlanogramSettings"
    case text = "TextSettings"
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
