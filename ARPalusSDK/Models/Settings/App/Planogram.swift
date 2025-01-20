//
//  Planogram.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 17.01.2025.
//

extension AppSettings {
    struct Planogram: Equatable, Codable {
        let version: Int
        let systemName: AppSettingName
        let tags: [String]
        let measurementUnit: Int
        let scanProgress: Int
        let scanProgressCountGeneral: Bool
        let minProgressForFinish: Double
        let packageIdThumbnails: Bool
//        let locationsLimit: []
        let redFlagProductImage: Bool
        let maxBarcodeScanningTime: Double
        let colorFlagCount: Int
        let showFinishScanButton: Bool
        let skipShelfCountCheckOnFinishScan: Bool
        let coloredBrandBB: Bool
        let coloredBrandBBAlpha: Double
        let discardPogIfTooSmallOrLarge: Bool
        let sequenceGapScalar: Double
        let similarityScore: Int
        let nonSimilarityPenalty: Int
        let realogramMatchingGapPenalty: Double
        let planogramMatchingGapPenalty: Double
        let realogramFitGapPenalty: Double
        let planogramFitGapPenalty: Double
        let overlayEnabled: Bool
        let pogHeightOnlyByShefOrder: Bool
        let medianHorizontalOffsetOverlay: Bool
        let bottomLeftHorizontalOffsetOverlay: Bool
        let pogManualPlacement: Bool
        let showReportPage: Bool
        let showPlanogramPage: Bool
        let showLocationPage: Bool
        let rememberLastPog: Bool
        let showRealogramInPlanogramPage: Bool
        let hidePogImageSpheres: Bool
        let hidePogImageGreenSpheres: Bool
        let showPogImageShelves: Bool
        let shelvesVisHeight: Double
        let showPogImageBarcodes: Bool
        let showPogImageBarcodesPerStack: Bool
        let showPogImageBarcodesUnified: Bool
        let showCleanPogImageCounts: Bool
        let showPogImageCountsNoColor: Bool
        let pogImageSpheresPerStack: Bool
        let pogImageSphereScale: Double
        let pogImageLabelScale: Double
        let markMissingProductsInRealogram: Bool
        let minScaleBetweenProducts: Double
        let realogramImageSpread: ImageSpread
        let showRealogramSvgLabels: Bool
        let showRealogramSvgGeneralProducts: Bool
        let showRealogramSvgMissingThumbnails: Bool
        let showRealogramSvgSpheres: Bool
        let showRealogramSvgShelfWidth: Bool
        let showRealogramSvgAlignStacks: Bool
        let showRealogramSvgAlignStacksShelves: Bool
        let showRealogramSvgCatalogDimensions: Bool
        let realogramSvgMinVoidWidth: Double
        let reportCountOrderDescending: Bool
        let productDisplayCode: Bool
        let sortStoresWithGPS: Bool
        let nearestStoreSelection: Bool
        let scanOnlyGPS: Bool
        let selectPrevStore: Bool
        let maxStoreDistance: Double
        let maxStoreDistanceFilter: Double
        let distanceWarningOnce: Bool
        let flipStoreOrder: Bool
        let maxReportCount: Int
        let reportProdCellOptsType: Int
        let reportDepthCount: Bool
        let reportProductsNotInPlan: Bool
        let reportGeneralProducts: Bool
        let showSpheresAllStores: Bool
        let reportSortProductsNotInPlan: Bool
        let reportSortSupplier: Bool
        let reportPlusMinus: Bool
        let reportNoCounts: Bool
        let reportAssortment: Bool
        let reportBrandsOnly: Bool
        let reportFilter: Bool
        let reportInventoryCounts: Bool
//        let reportInventoryCategories: []
        let sendEmptyReports: Bool
        let sendEmailReport: Bool
        let emailAttachmentCsv: Bool
        let emailAttachmentImageEnabled: Bool
        let showLegendReportPage: Bool
        let reportAllProducts: Bool
        let sendEmailReportTo: [String]
        let maxPostScanProcessingTime: Double
//        let shareOfShelfBrands: []
//        let shareOfShelfOtherBrands: []
        let minDistanceForPlanogramUpdate: Double
        let sizeBOWEnabled: Bool
        let sizeBOWThreshold: Double
        let productWidthScaleForPositionFit: Double
        let productHeightScaleForPositionFit: Double
        let posterModeMinDistance: Double
        let clusterShelves: Bool
        let detectUnifiedShelves: Bool
        let timeout: Int
        let bbPadingForHeuristicShelfDetection: Double
        let minFixtureFitScore: Double
        let shelfDepthIsFrontFeaturePoints: Bool
        let stackProducts: Bool
        let stackingProductsToBottomOfShelf: Bool
        let stackReportWithMissingProducts: Bool
        let productRescaleHeightvsWidthRatio: Bool
        let reportShowPogCompCell: Bool
        let reportShowPogCompCircle: Bool
        let reportShowVoidsCircle: Bool
        let reportGroupProductsBySupplier: Bool
        let reportGroupProductsByCountCategories: Bool
        let reportProductsShowMaxCapacity: Bool
        let reportProdsMaxCapForSingleFace: Bool
        let reportAlertedProductColor: RGBA
        let simplePogLocalizationAnchor: String
        let tutorialPrivateSubDirectory: String
        let tutorialVideoFilename: String
        let tutorialSlideImageBaseFilename: String
        let tutorialSlideImageExtension: String
        let showScanCoverMarkers: Bool
        let scanTargetSize: Double
        let scanCoverMode: Int
        let targetMatchDist: Double
        let scanMarkerScaleFactor: Double
        let scanHoverTime: Double
        let showScanAreaLines: Bool
        let scanLimitsLineColor: RGBA
        let scanLimitsLineWidth: Double
        let showCrosshair: Bool
        let showHurrayNotification: Bool
        let minHurrayInterval: Double
        let maxHurrayInterval: Double
        let stackOverlapThreshold: Double
        let cropsCountForDepthCount: Int
    }
}

extension AppSettings.Planogram {
    struct RGBA: Equatable, Codable {
        let r: Double
        let g: Double
        let b: Double
        let a: Double
    }
}

extension AppSettings.Planogram {
    struct ImageSpread: Equatable, Codable {
        let x: Double
        let y: Double
    }
}
