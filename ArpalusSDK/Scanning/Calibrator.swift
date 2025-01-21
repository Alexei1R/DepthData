//
//  Calibrator.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import ARKit

typealias Degrees = Double

let CYLINDER_RADIUS = 0.03

final class Calibrator {

    enum Result: Equatable {
        case invalidPitch
        case invalidRoll
        case cannotComputeOrigin
        case tooClose
        case inProgress
        case calibrated(simd_float4x4)
    }

    private var stableFrameCount = 0
    private let requiredStableFrames = 30

    let camera: AppSettings.Camera
    let vision: AppSettings.Vision
    lazy var originCalculator: OriginCalculator = ARWorldTrackingConfiguration
        .supportsFrameSemantics(.sceneDepth) && false ? DepthMapOriginCalculator() : FeaturePointsOriginCalculator(vision: vision)

    init(camera: AppSettings.Camera, vision: AppSettings.Vision) {
        self.camera = camera
        self.vision = vision
    }

    func calibrateOrigin(frame: ARFrame) -> Result {
        let eulerAngles = frame.camera.eulerAngles

        print("Pitch: \(cameraPitch(eulerAngles)); Roll: \(cameraRoll(eulerAngles))")

        let isPitchValid = abs(cameraPitch(eulerAngles)) <= camera.captureAnglePitch
        let isRollValid = abs(cameraRoll(eulerAngles)) <= camera.captureAngleRoll

        guard isPitchValid else {
            stableFrameCount = 0
            return .invalidPitch
        }
        guard isRollValid else {
            stableFrameCount = 0
            return .invalidRoll
        }

        guard let origin = computeOriginPoint(frame: frame) else {
            return .cannotComputeOrigin
        }

        let distance = simd_distance(frame.camera.transform.columns.3, origin.columns.3)

        if Double(distance) < vision.minStartingDistance {
            return .tooClose
        }

        stableFrameCount += 1

        if stableFrameCount < requiredStableFrames {
            return .inProgress
        }

        return .calibrated(origin)
    }

    func reset() {
        stableFrameCount = 0
    }

    private func cameraPitch(_ eulerAngles: simd_float3) -> Degrees {
        let pitch = eulerAngles.x > .pi / 2 ? eulerAngles.x - .pi : eulerAngles.x
        return Degrees(abs(pitch * 180 / .pi))
    }

    private func cameraRoll(_ eulerAngles: simd_float3) -> Degrees {
        let normalizedRoll = eulerAngles.z + .pi / 2
        let adjustedRoll = normalizedRoll > .pi ? normalizedRoll - 2 * .pi : normalizedRoll
        let roll = adjustedRoll > .pi / 2 ? adjustedRoll - .pi : adjustedRoll
        return Degrees(abs(roll * 180 / .pi))
    }

    private func computeOriginPoint(frame: ARFrame) -> simd_float4x4? {
        guard let originPosition = originCalculator.compute(frame) else { return nil }
        // Get the camera transform
        var newOrigin = frame.camera.transform
        newOrigin.columns.3 = simd_float4(originPosition, 1)

        return newOrigin
    }
}

extension UnsafeMutablePointer {
    func valueAt(x: Int, y: Int, rowWidth: Int) -> Pointee {
        let centerIndex = y * rowWidth + x
        return self[centerIndex]
    }
}
