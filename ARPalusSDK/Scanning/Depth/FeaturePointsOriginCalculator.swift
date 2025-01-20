//
//  FeaturePointsOriginCalculator.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import ARKit

final class FeaturePointsOriginCalculator: OriginCalculator {
    private var featureBasedShelfDepthCount: Int = 0
    private var featureBasedShelfDepthPoint: simd_float3?

    private let vision: AppSettings.Vision

    init(vision: AppSettings.Vision) {
        self.vision = vision
    }

    func compute(_ frame: ARFrame) -> simd_float3? {
        let (depthCount, depthPoint) = getDepthAroundCameraRay(frame: frame)

        // Validate the depth point
        guard let depthPoint else { return featureBasedShelfDepthPoint }
        let distance = Double(getDistanceFromShelf(
          shelfPoint: depthPoint,
          cameraPosition: frame.camera.transform.columns.3.xyz
        ))
        guard distance >= vision.minStartingDistance,
              distance >= vision.minDetectionDistance
        else { return featureBasedShelfDepthPoint }

        // Update running average with new point
        featureBasedShelfDepthCount += depthCount

        // Calculate lerp speed based on point confidence
        let lerpSpeed = Float(depthCount) / Float(featureBasedShelfDepthCount)
        let clampedSpeed = simd_clamp(lerpSpeed, 0.01, 1.0)

        // Initialize or update smoothed position
        if featureBasedShelfDepthPoint == nil {
            featureBasedShelfDepthPoint = depthPoint
        } else {
            featureBasedShelfDepthPoint = simd_mix(
                featureBasedShelfDepthPoint!,
                depthPoint,
                simd_float3(repeating: clampedSpeed)
            )
        }

        return featureBasedShelfDepthPoint
    }

    private func getDistanceFromShelf(shelfPoint: simd_float3, cameraPosition: simd_float3) -> Float {
        simd_distance(shelfPoint, cameraPosition)
    }

    func reset() {
        featureBasedShelfDepthCount = 0
        featureBasedShelfDepthPoint = nil
    }

    private func getDepthAroundCameraRay(
        frame: ARFrame,
        maxDistance: Float = 0.04,
        rayLength: Float = 2.5
    ) -> (count: Int, frontPoint: simd_float3?) {
        let camera = frame.camera
        let cameraTransform = camera.transform
        let cameraPosition = cameraTransform.columns.3.xyz
        let cameraForward = -simd_normalize(cameraTransform.columns.2.xyz)

        return getDepthAroundRay(
            rayOrigin: cameraPosition,
            rayDirection: cameraForward,
            rayLength: rayLength,
            maxDistance: maxDistance,
            frame: frame
        )
    }
    private func getDepthAroundRay(
        rayOrigin: simd_float3,
        rayDirection: simd_float3,
        rayLength: Float,
        maxDistance: Float,
        frame: ARFrame
    ) -> (count: Int, frontPoint: simd_float3?) {
        let rayEnd = rayOrigin + rayDirection * rayLength
        return getDepthAroundLine(
            lineStart: rayOrigin,
            lineEnd: rayEnd,
            maxDistance: maxDistance,
            frame: frame
        )
    }

    private func getDepthAroundLine(
        lineStart: simd_float3,
        lineEnd: simd_float3,
        maxDistance: Float,
        frame: ARFrame
    ) -> (count: Int, frontPoint: simd_float3?) {
        // Get raw feature points from current frame
        guard let points = frame.rawFeaturePoints?.points else {
            return (0, nil)
        }

        // Filter points near the line
        let nearbyPoints = points.filter { point in
            squaredDistanceFromPointToLine(
                point: point,
                lineStart: lineStart,
                lineEnd: lineEnd
            ) < maxDistance
        }

        guard nearbyPoints.count >= 10 else {
            return (0, nil)
        }

        // Sort points by distance to camera
        let cameraPosition = frame.camera.transform.columns.3.xyz
        let sortedPoints = nearbyPoints.sorted { p1, p2 in
            simd_distance_squared(p1, cameraPosition) < simd_distance_squared(p2, cameraPosition)
        }

        // Take 5% slice of points from the sorted array
        let startIndex = Int(ceil(Double(sortedPoints.count) * 0.05))
        let length = Int(ceil(Double(sortedPoints.count) * 0.05))

        guard startIndex + length <= sortedPoints.count else {
            return (0, nil)
        }

        // Calculate average position from the slice
        let slicedPoints = Array(sortedPoints[startIndex..<(startIndex + length)])
        let averagePoint = slicedPoints.reduce(simd_float3(), +) / Float(slicedPoints.count)

        return (slicedPoints.count, averagePoint)
    }

    private func squaredDistanceFromPointToLine(
        point: simd_float3,
        lineStart: simd_float3,
        lineEnd: simd_float3
    ) -> Float {
        let line = lineEnd - lineStart
        let pointVector = point - lineStart

        let lineLengthSquared = simd_length_squared(line)
        guard lineLengthSquared > 0 else {
            return simd_length_squared(pointVector)
        }

        let t = simd_dot(pointVector, line) / lineLengthSquared
        let projection = lineStart + t * line

        return simd_distance_squared(point, projection)
    }
}
