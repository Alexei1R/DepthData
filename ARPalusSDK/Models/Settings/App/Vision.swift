//
//  Vision.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

extension AppSettings {
    struct Vision: Equatable, Codable {
        let version: Int
        let systemName: AppSettingName
        let tags: [String]
//        var inferenceJobsEnabled: Bool = false
//        let postSpecificDetections: Bool
//        let anchorDistance: Double
//        let enableAnchors: Bool
//        let useOnnxRuntime: Bool
//        let specificGrid: Bool
//        let multiScanMultiSegments: Bool
//        let nextSegmentDetectionCount: Int
//        let multiScanMultiSegmentsWaitTime: Double
//        let multiAngleVoting: Bool
//        let multiAngleDetection: MultiAngleDetection
//        let processingEnabled: Bool
//        let resultProcessingMod: Int
//        let downloadModels: Bool
//        let refreshNameMaps: Bool
//        let processResultsAtMinFPS: Int
//        let catalogSizeEnabled: Bool
//        let maxCatalogSizeLengthFactor: Double
//        let maxCatalogSizeAreaFactor: Double
//        let autoAngle: Bool
//        let verticalPlaneAngleTimer: Double
//        let verticalPlaneAngleRange: Double
//        let autoAngleAutoStart: Bool
//        let featurePointCount: Int
//        let minFeaturePointsForShelfAngle: Int
//        let minFeaturePointsForShelfDistance: Int
//        let featurePointFilterDistance: Double
//        let verticalPlaneAngleFixCentroids: Bool
//        let minWidthCentroids: Double
//        let maxDistanceVerticalPlaneLine: Double
//        let overheatReleaseAllFrames: Bool
//        let overheatConsecutiveLoops: Int
//        let overheatTimeLimit: Double
//        let overheatTimeToWait: Double
//        let overheatWarning: Bool
//        let shelfDetection: Bool
//        let enableShelfTagging: Bool
//        let shelfDetectionFramesMod: Int
//        let shelfModelNameContains: String
//        let generalProductDetection: Bool
//        let generalProductDetectionCreateOnly: Bool
//        let generalProductDetectionFramesMod: Int
//        let generalProductModelNameContains: String
//        let shelfVisualization: Bool
//        let manualShelfDetection: Bool
//        let shelfDepth: Double
//        let shelfMinDepth: Double
//        let filterDepthDetections: Bool
//        let keepShelfWidth: Bool
//        let keepShelfHeight: Bool
//        let minHeightBetweenShelves: Double
//        let belowSimulatedShelfSpace: Double
//        let shelfHeightOffset: Double
//        let shelfCorrectionBelowProductsRatio: Double
//        let addSimulatedShelfDetections: Bool
//        let minProductsAboveDetectedShelf: Int
//        let removeShelvesWithoutProductsAfterScan: Bool
//        let adjustShelvesBBsPostScan: Bool
//        let disableDetectingShelvesWithoutProductsDuringScan: Bool
//        let assumedMinShelfWidthBeyondDetectionPos: Double
//        let perImageDepthMap: Bool
//        let depthMapSavedResolution: Int
//        let depthResolution: Double
//        let minFeaturesPointsForProduct: Int
//        let depthMapSizeWidth: Double
//        let depthMapSizeHeight: Double
//        let depthMapCellSizeLOD_x: [Double]
//        let depthMapCellSizeLOD_y: [Double]
//        let minNumOfFeaturesPerDepthMapCell: Int
//        let imageBlurTestEnabled: Bool
//        let imageBlurBufferSize: Int
//        let imageBlurMinAverageScalar: Double
//        let confThreshold: Double
//        let confThresholdSpecific: Double
//        let confThresholdShelf: Double
//        let nmsThreshold: Double
//        let debugSpecificModel: String
//        let inpWidth: Int
//        let inpHeight: Int
//        let gridCellSize: Int
//        let gridSize: Int
//        let minNumDetections: Int
//        let requireSpecificDetections: Bool
//        let maxLoadedModels: Int
//        let posterTracking: Bool
//        let minDetectionAngle: Int
//        let minDetectionDistance: Double
//        let maxDetectionDistance: Double
//        let acceptFrontalSideDetections: Bool
//        let maxProcessingDistanceX: Double
//        let quadPosOffsetZ: Double
//        let quadWidthScaleFactor: Double
//        let quadHeightScaleFactor: Double
//        let quadDepthScale: Double
//        let useLegacyBBScalePosUpdateAvg: Bool
//        let detectionScaleUpdateRate: Double
//        let detectionPositionUpdateRate: Double
//        let legacyDetectionScaleUpdateRate: Double
//        let legacyDetectionPositionUpdateRate: Double
//        let bbScaleUpdateMaxWinSize: Int
//        let bbPositionUpdateMaxWinSize: Int
//        let removeOverlaps: Bool
//        let resizeOverlaps: Bool
//        let moveOverlaps: Bool
//        let maxBBMotionScaleFactor: Double
//        let maxAllowedBBOverlapPortion: Double
//        let BBTotalOverlapPortionForRemoval: Double
//        let BBOverlapPortionForRemoval: Double
//        let overlapFixPace: Double
//        let maxNumDetectionsForOverlapWeight: Int
//        let maxSameBBDetectionsCountAvg: Double
//        let bbCenterPortion: Double
//        let centerDistPullingThreshold: Double
//        let minCenterProximityWeight: Double
//        let resetThresholdBBCenterDetectionPortion: Double
//        let removalThresholdBBCenterDetectionPortion: Double
//        let minDetectionsForBBReplacement: Int
//        let maxVisibleTimeWithoutDetections: Double
//        let projectDetectionOnAllBBs: Bool
//        let maxDistFromClosestBB: Double
//        let imageBoundarySize: Double
//        let runDeepClassifierOnDetections: Bool
//        let classifierBoundingBoxSizeFactor: Double
//        let classifierMaxRes: Double
//        let classifierMinRes: Double
//        let skipSpecificModelForHighConfidenceDetections: Bool
//        let skipSpecificModelForHighConfidenceImages: Bool
//        let highConfidenceBestSpecificMinRatio: Double
//        let highConfidenceBestSpecificMinLead: Double
//        let highConfidenceMinSpecificDetections: Int
//        let runClassifierAfterMinDetectorFailures: Int
//        let frameTimeFactorToLimitSpecificProcessing: Double
//        let autoTagRedFlags: Bool
//        let autoTagRedFlagsPackageId: String
//        let generalProductPackageId: String
//        let enableLiveTag: Bool
//        let autoGeneralTag: Bool
//        let autoGeneralTagOnScanDone: Bool
//        let liveTagProductPositionBrands: Bool
//        let showDeleteDetectionButton: Bool
//        let tagPackageIdFromBarcode: Bool
//        let tagDeleteProduct: String
//        let tagNegativeProduct: String
//        let tagNegativeSpace: String
//        let tagIdDeleteProduct: Int
//        let CategoryCooldown: Double
//        let percentageToForceRunCategoryModel: Double
//        let runAllCategoryModels: Bool
//        let autoTagClipThreshold: Double
//        let useDominantSizeMappingAxisOnly: Bool
//        let isDepthAPIEnabled: Bool
//        let setScreenResolution: Bool
//        let reloadShelfModel: Bool
    }
}

extension AppSettings.Vision {
    struct MultiAngleDetection: Equatable, Codable {
        let bestCountPerDirection: Int
        let edgeWeightScale: Double
        let directionBinWeightFactor: Double
        let angleXRange: Double
        let angleXSlices: Int
        let angleYRange: Double
        let angleYSlices: Int
    }
}
