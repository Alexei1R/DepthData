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

        print("Pitch: \(eulerAngles.cameraPitch); Roll: \(eulerAngles.cameraRoll)")

        let isPitchValid = abs(eulerAngles.cameraPitch) <= camera.captureAnglePitch
        let isRollValid = abs(eulerAngles.cameraRoll) <= camera.captureAngleRoll

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

    private func computeOriginPoint(frame: ARFrame) -> simd_float4x4? {
        guard let originPosition = originCalculator.compute(frame) else { return nil }
        
        // Get the camera's forward direction and project it onto XZ plane
        let cameraTransform = frame.camera.transform
        let cameraForward = cameraTransform.columns.2.xyz
        
        // Calculate right vector by crossing world up with forward
        let up = simd_float3(0, 1, 0)
        let right = -simd_normalize(simd_cross(up, cameraForward))
        
        let forward = simd_normalize(simd_cross(up, right))
        
        // Construct the new transform matrix
        return simd_float4x4(
            columns: (
                simd_float4(right, 0),
                simd_float4(up, 0),
                simd_float4(forward, 0),
                simd_float4(originPosition, 1)
            )
        )
    }
}

extension simd_float3 {
    var cameraPitch: Degrees {
        let pitch = x > .pi / 2 ? x - .pi : x
        return Degrees(abs(pitch * 180 / .pi))
    }
    
    var cameraRoll: Degrees {
        let adjustedRoll = z > .pi ? z - 2 * .pi : z
        let roll = adjustedRoll > .pi / 2 ? adjustedRoll - .pi : adjustedRoll
        return Degrees(abs(roll * 180 / .pi))
    }
}

extension UnsafeMutablePointer {
    func valueAt(x: Int, y: Int, rowWidth: Int) -> Pointee {
        let centerIndex = y * rowWidth + x
        return self[centerIndex]
    }
}

func customDecode<T: Codable>(data: Data, defaultValue: T) throws -> T {
    let defaultData = try JSONEncoder().encode(defaultValue)
    let defaultDict = try JSONSerialization.jsonObject(with: defaultData, options: []) as? [String: Any]

    let currentDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    guard let currentDict else { return defaultValue }

    let mergedDict = defaultDict?.merging(currentDict) { old, new in
        // Go 1-layer deep for nested models. Won't work if the nesting goes 2-layers
        if let oldNestedDict = old as? [String: Any], let newNestedDict = new as? [String: Any] {
            return oldNestedDict.merging(newNestedDict) { _, new in new }
        } else {
            return new
        }
    } ?? currentDict
    let mergedData = try JSONSerialization.data(withJSONObject: mergedDict)

    return try JSONDecoder().decode(T.self, from: mergedData)
}
