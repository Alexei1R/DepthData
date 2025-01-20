//
//  CameraConfig.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import ARKit

enum CameraConfig {
    static func bestCameraConfig(
        settings: AppSettings.Camera,
        formats: [ARConfiguration.VideoFormat]
    ) -> ARConfiguration.VideoFormat? {
        if formats.isEmpty { return nil }
        if formats.count == 1 { return formats[0] }
        let minFrameRate = 30

        return formats[1..<formats.count].reduce(into: formats[0]) { bestFormat, format in
            let configWidthDistance = abs(settings.preferredCameraConfigWidth - format.height)
            let bestConfigWidthDistance = abs(settings.preferredCameraConfigWidth - bestFormat.height)
            guard format.height >= settings.preferredCameraConfigWidth && configWidthDistance <= bestConfigWidthDistance else {
                return
            }
            guard format.framesPerSecond <= bestFormat.framesPerSecond || bestFormat.framesPerSecond < minFrameRate else {
                return
            }
            let aspectRatio = format.imageResolution.width / format.imageResolution.height
            let aspectRatioDistance = abs(settings.targetCameraAspectRatio - aspectRatio)

            let bestAspectRatio = bestFormat.imageResolution.width / bestFormat.imageResolution.height
            let bestAspectRatioDistance = abs(settings.targetCameraAspectRatio - bestAspectRatio)

            guard aspectRatioDistance <= bestAspectRatioDistance else { return }
            bestFormat = format
        }
    }
}

extension ARConfiguration.VideoFormat {
    var height: Int {
        Int(imageResolution.height)
    }
}
