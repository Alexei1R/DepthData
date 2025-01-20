//
//  Debug.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

extension AppSettings {
    struct Debug: Equatable, Codable {
        let version: Int
        let systemName: AppSettingName
        let tags: [String]
        let backgroundUploadEnabled: Bool
        let storageUrl: String
        let showDisconnectedIcon: Bool
        let setPageBackgroundColorOnPendingUploads: Bool
        let showTutorialButtons: Bool
        let showLogoutButton: Bool
        let checkPublicAppVersion: Bool
        let alwaysShowFPS: Bool
        let uploadLogsInAR: Bool
        let basicRenderMode: Bool
        let alwaysShowSettingsText: Bool
        let showBbCountsInPogImage: Bool
        let previewShelf: Bool
        let debugARSpecificBB: Bool
        let debugFrustumPlanes: Bool
        let debugResultFrustumPlanes: Bool
        let debugARPlanogramBorder: Bool
        let debugARMarker: Bool
        let debugARMarkerLabel: Bool
        let debugProductSpheres: Bool
        let hideProductSpheres: Bool
        let productSpheresScale: Double
        let disableWarningPanel: Bool
        let displayLodDepthMap: Bool
        let showDepthMapFeaturePoints: Bool
        let showDepthCellOnRayHit: Bool
        let debugPlaneOrigin: Bool
        let debugCameraDistance: Bool
        let debugAnchors: Bool
        let showAllDetectedBBs: Bool
        let slackOnStartUpload: Bool
        let lowMemoryLimit: Int
        let minMemoryFreeMbBeforeScan: Int
        let haltDetectionsOnScreenTouch: Bool
        let drawDetectionRays: Bool
        let showShelfQuad: Bool
        let sendCategoryInferenceStatistics: Bool
        let uploadTempLogs: Bool
        let uploadDepthMap: Bool
        let saveDetectionImages: Bool
        let finishScanOnUnpause: Bool
        let finishScanOnUnpauseTime: Double
        let minWarningInterval: Double
        let duplicateScan: Int
        let maxThumbnailsFileSizeMb: Int
    }
}
