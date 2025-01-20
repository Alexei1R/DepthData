//
//  Camera.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

extension AppSettings {
    struct Camera: Equatable, Codable {
        let version: Int
        let systemName: AppSettingName
        let tags: [String]
        let captureAnglePitch: Double
        let captureAngleYaw: Double
        let captureAngleRoll: Double
//        let imageSaveMode: Int
//        let newDetectionSaveImageThreshold: Int
//        let minNumofImagesToUpload: Int
//        let useXSortingForDashboardImages: Bool
//        let shelfCoverageCellsSize: Double
        let shelfCoverageCellsSize: Double
        let shelfCoverageMinRatio: Double
//        let edgeShelfCoverageMinRatio: Double
//        let shelfCoverageLog: Bool
//        let cropDashboardImages: Bool
        let lowerSaveResolution: Bool
        let saveResolutionWidth: Int
        let preferredCameraConfigWidth: Int
        let targetCameraAspectRatio: Double
//        let cameraCaptuerFrameCount: Int
//        let maxCameraFrameCaptureToUpload: Int
//        let finishScanOnMaxImageLimit: Bool
//        let capturePerSecond: Int
//        let resumeCaptureOnShowResults: Bool
//        let minDistanceToZoom: Double
////        let capturePerSecond_platform: []
//        let maxNumOfSkippedFrames: Int
//        let minAngleBetweenCapturesHighThreshold: Double
//        let filterFactor: Double
//        let distanceBaseFactor: Double
//        let saveCaptureIntervalInSeconds: Double
//        let captureAtMinFPS: Int
//        let minMegsFreeMemory: Int
//        let maxMegsSaveCaptureLimit: Int
//        let maxKeepFramesLimit: Int
//        let maxKeepFramesPostScanLimit: Int
////        let maxKeepFramesLimit_platform: []
////        let maxKeepFramesPostScanLimit_platform: []
//        let zoomCropFractions: [Double]
//        let processSquareCrops: Bool
//        let delayBetweenInstructions: Double
//        let angleTooSteepWarning: Bool
//        let tooCloseToShelfWarning: Bool
//        let tooFarToShelfWarning: Bool
//        let motionSpeedWarning: Bool
//        let maxMotionAccelerationSpeed: Double
//        let maxMotionAngularAccelerationSpeed: Double
//        let motionSpeedDelayWarning: Double
//        let maxWarningsThreshold: Int
//        let maxWarningsTimeframe: Double
//        let minScanTimeInSeconds: Double
//        let minScanImagesTaken: Int
//        let minCapturePerSecond: Int
//        let captureAngleMaxZ: Double
//        let uploadRealogramImageToDashboard: Int
    }
}

extension AppSettings.Camera {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        systemName = try container.decode(AppSettingName.self, forKey: .systemName)
        tags = try container.decode([String].self, forKey: .tags)

        shelfCoverageCellsSize = try container.decodeIfPresent(Double.self, forKey: .shelfCoverageCellsSize) ?? 0.25
        shelfCoverageMinRatio = try container.decodeIfPresent(Double.self, forKey: .shelfCoverageMinRatio) ?? 0.25

        lowerSaveResolution = try container.decodeIfPresent(Bool.self, forKey: .lowerSaveResolution) ?? true
        saveResolutionWidth = try container.decodeIfPresent(Int.self, forKey: .saveResolutionWidth) ?? 720
        preferredCameraConfigWidth = try container.decodeIfPresent(Int.self, forKey: .preferredCameraConfigWidth) ?? 720
        targetCameraAspectRatio = try container.decodeIfPresent(Double.self, forKey: .targetCameraAspectRatio) ?? 4.0 / 3

        captureAnglePitch = try container.decodeIfPresent(Double.self, forKey: .captureAnglePitch) ?? 35
        captureAngleYaw = try container.decodeIfPresent(Double.self, forKey: .captureAngleYaw) ?? 35
        captureAngleRoll = try container.decodeIfPresent(Double.self, forKey: .captureAngleRoll) ?? 20
    }
}
