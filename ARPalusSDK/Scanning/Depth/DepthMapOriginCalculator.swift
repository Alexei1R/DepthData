//
//  DepthMapOriginCalculator.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import ARKit

struct DepthMapOriginCalculator: OriginCalculator {
    func compute(_ frame: ARFrame) -> simd_float3? {
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
        
        // Get the camera transform and position
        let cameraTransform = frame.camera.transform
        let cameraPosition = cameraTransform.columns.3.xyz

        // Move along the camera's forward direction (negative Z in camera space)
        let forward = simd_float3(
            -cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z
        )

        // Return the world space point by adding the offset to camera position
        return cameraPosition + forward * averageDistance

        // Move from camera position along the forward vector
//        originPoint.columns.3 = originPoint.columns.3 + simd_float4(forward * averageDistance, 0)
//
//        return (centerDepth, originPoint)
    }
}
