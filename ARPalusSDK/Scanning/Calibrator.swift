//
//  Calibrator.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import ARKit

typealias Degrees = Double

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
    private let requiredStableFrames = 5

    let camera: AppSettings.Camera
    let vision: AppSettings.Vision

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
        stableFrameCount += 1

        guard let (distance, origin) = computeOriginPoint(frame: frame) else {
            return .cannotComputeOrigin
        }

        if Double(distance) < vision.minStartingDistance {
            return .tooClose
        }

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

    private func computeOriginPoint(frame: ARFrame) -> (distance: Float32, origin: simd_float4x4)? {
        guard let depthMap = frame.sceneDepth?.depthMap else { return nil }

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        // Calculate center point
        let centerX = width / 2
        let centerY = height / 2

        // Lock the buffer for reading
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        // Get pointer to depth data
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return nil }
        let buffer = baseAddress.assumingMemoryBound(to: Float32.self)

        // Get depth value at center point (in meters)
        let centerDepth = buffer.valueAt(x: centerX, y: centerY, rowWidth: width)

        let fov = frame.camera.fov
        let distanceX = tan(fov.x / 2) * centerDepth * 2
        //        let distanceY = tan(fov.y / 2) * centerDepth * 2

        let distancePerPixel = distanceX / Float(width)
        //        let distanceYPerPixel = distanceY / Float(height)

        let pixelsPerSide = Int(CYLINDER_RADIUS / Double(distancePerPixel))

        var count = 0
        var sum: Float32 = 0
        for i in (centerX - pixelsPerSide)...(centerX + pixelsPerSide) {
            for j in (centerY - pixelsPerSide)...(centerY + pixelsPerSide) {
                let xDeltaPixels = centerX - i
                let yDeltaPixels = centerY - j
                let distance = sqrt(Double(xDeltaPixels * xDeltaPixels + yDeltaPixels * yDeltaPixels))
                if distance > Double(pixelsPerSide) { break }
                let depth = buffer.valueAt(x: i, y: j, rowWidth: width)
                if depth.isNaN { break }
                count += 1
                sum += depth
            }
        }
        let averageDistance = sum / Float32(count)
        // Get the camera transform
        var originPoint = frame.camera.transform

        // Move along the camera's forward direction (negative Z in camera space)
        let forward = simd_float3(
            -originPoint.columns.2.x,
             -originPoint.columns.2.y,
             -originPoint.columns.2.z
        )

        // Move from camera position along the forward vector
        originPoint.columns.3 = originPoint.columns.3 + simd_float4(forward * averageDistance, 0)

        return (centerDepth, originPoint)
    }
}

extension UnsafeMutablePointer {
    func valueAt(x: Int, y: Int, rowWidth: Int) -> Pointee {
        let centerIndex = y * rowWidth + x
        return self[centerIndex]
    }
}
