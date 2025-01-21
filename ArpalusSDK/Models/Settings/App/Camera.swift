//
//  Camera.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

extension AppSettings {
    struct Camera: Equatable, Codable {
        var version = 0
        var systemName: AppSettingName = .camera
        var tags: [String] = []
        var captureAnglePitch: Double = 35
        var captureAngleYaw: Double = 35
        var captureAngleRoll: Double = 20
//        let imageSaveMode: Int
//        let newDetectionSaveImageThreshold: Int
//        let minNumofImagesToUpload: Int
//        let useXSortingForDashboardImages: Bool
//        let shelfCoverageCellsSize: Double
        var shelfCoverageCellsSize = 0.25
        var shelfCoverageMinRatio = 0.25
//        let edgeShelfCoverageMinRatio: Double
//        let shelfCoverageLog: Bool
//        let cropDashboardImages: Bool
        var lowerSaveResolution = true
        var saveResolutionWidth = 720
        var preferredCameraConfigWidth = 720
        var targetCameraAspectRatio = 4.0 / 3
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
        var angleTooSteepWarning = true
        var tooCloseToShelfWarning = true
        var tooFarToShelfWarning = true
        var motionSpeedWarning = true
        var maxMotionAccelerationSpeed = 0.2
        var maxMotionAngularAccelerationSpeed: Double = 4
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
