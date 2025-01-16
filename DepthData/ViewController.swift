//
//  ViewController.swift
//  ARLogo
//
//  Created by Alex Culeva on 07.09.2024.
//

import UIKit
import SceneKit
import ARKit

let CYLINDER_RADIUS = 0.03
let PLANE_SIZE = simd_float2(0.1, 0.1)
let OVERLAP_VALUE : Float = 1.1

class ViewController: UIViewController, ARSCNViewDelegate {
    
    let sceneView = ARSCNView()
    
    var origin: simd_float4x4?
    
    private var placedPositions: Set<SIMD2<Float>> = []
    
    private let nearClip: Float = 0.01  // 1cm
    private let farClip: Float = 5.0    // 5m
    private var visibleNodes: [SIMD2<Float>: SCNNode] = [:]
    
    deinit {
        print("")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sceneView)
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: sceneView.topAnchor),
            view.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor),
            view.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor),
            
        ])
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.preferredFramesPerSecond = 60
        sceneView.automaticallyUpdatesLighting = true
        sceneView.session.delegate = self
        
        //        sceneView.debugOptions.insert(.dept)
        
        // Create a session configuration for world tracking
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
        sceneView.session.run(configuration)
    }
    
    private func computeOriginPoint(frame: ARFrame) -> simd_float4x4? {
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
        
        return originPoint
    }
    
    private func drawPlane(transform: simd_float4x4, color: UIColor = .red) {
        let planeGeometry = SCNPlane(width: CGFloat(PLANE_SIZE.x),
                                     height: CGFloat(PLANE_SIZE.y))
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        planeGeometry.materials = [planeMaterial]
        
        let node = SCNNode(geometry: planeGeometry)
        node.simdTransform = transform
        
        sceneView.scene.rootNode.addChildNode(node)
    }
}


private func getFrustumDimensions(fov: simd_float2, aspectRatio: Float, nearClip: Float, farClip: Float) -> (near: simd_float2, far: simd_float2) {
    let nearHeight = 2 * tan(fov.y / 2) * nearClip
    let nearWidth = nearHeight * aspectRatio
    let farHeight = 2 * tan(fov.y / 2) * farClip
    let farWidth = farHeight * aspectRatio
    
    return (near: simd_float2(nearWidth, nearHeight), far: simd_float2(farWidth, farHeight))
}


extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let origin else {
            if let originPoint = computeOriginPoint(frame: frame) {
                self.origin = originPoint
                drawPlane(transform: originPoint, color: .blue)
            }
            return
        }

        // Get camera properties
        let camera = frame.camera
        let cameraTransform = camera.transform
        let cameraPos = simd_float3(cameraTransform.columns.3.x, 
                                   cameraTransform.columns.3.y, 
                                   cameraTransform.columns.3.z)
        
        // Calculate camera orientation vectors
        let forward = -simd_normalize(simd_float3(cameraTransform.columns.2.x,
                                                cameraTransform.columns.2.y,
                                                cameraTransform.columns.2.z))
        let right = simd_normalize(simd_float3(cameraTransform.columns.0.x,
                                             cameraTransform.columns.0.y,
                                             cameraTransform.columns.0.z))
        let up = simd_normalize(simd_float3(cameraTransform.columns.1.x,
                                          cameraTransform.columns.1.y,
                                          cameraTransform.columns.1.z))

        // Get actual camera FOV
        let fov = camera.fov
        let horizontalFOV = fov.x
        let verticalFOV = fov.y

        // Calculate frustum corners at different distances
        let distances: [Float] = [nearClip, farClip/2, farClip]
        var gridPositionsToCheck: Set<SIMD2<Float>> = []

        for distance in distances {
            // Calculate frustum dimensions at this distance
            let frustumHeight = 2.0 * distance * tan(verticalFOV / 2.0)
            let frustumWidth = 2.0 * distance * tan(horizontalFOV / 2.0)
            
            // Calculate frustum corners in camera space
            let corners: [simd_float3] = [
                // Top-left
                cameraPos + forward * distance - right * (frustumWidth/2) + up * (frustumHeight/2),
                // Top-right
                cameraPos + forward * distance + right * (frustumWidth/2) + up * (frustumHeight/2),
                // Bottom-left
                cameraPos + forward * distance - right * (frustumWidth/2) - up * (frustumHeight/2),
                // Bottom-right
                cameraPos + forward * distance + right * (frustumWidth/2) - up * (frustumHeight/2)
            ]

            // Calculate grid positions that could fit within these corners
            let gridSpacingX = PLANE_SIZE.x * OVERLAP_VALUE
            let gridSpacingY = PLANE_SIZE.y * OVERLAP_VALUE

            // Find bounds of the grid area
            let minX = corners.map { $0.x }.min()! - gridSpacingX
            let maxX = corners.map { $0.x }.max()! + gridSpacingX
            let minY = corners.map { $0.y }.min()! - gridSpacingY
            let maxY = corners.map { $0.y }.max()! + gridSpacingY

            // Round to nearest grid positions
            let startX = round(minX / gridSpacingX) * gridSpacingX
            let endX = round(maxX / gridSpacingX) * gridSpacingX
            let startY = round(minY / gridSpacingY) * gridSpacingY
            let endY = round(maxY / gridSpacingY) * gridSpacingY

            // Add potential grid positions
            var x = startX
            while x <= endX {
                var y = startY
                while y <= endY {
                    let gridPosition = SIMD2<Float>(x, y)
                    gridPositionsToCheck.insert(gridPosition)
                    y += gridSpacingY
                }
                x += gridSpacingX
            }
        }

        // Check each potential grid position
        for gridPosition in gridPositionsToCheck {
            // Skip if already placed
            if placedPositions.contains(gridPosition) {
                continue
            }

            // Calculate world position
            let worldPos = simd_float3(gridPosition.x, gridPosition.y, origin.columns.3.z)
            let toGrid = worldPos - cameraPos

            // Check if in front of camera
            let distanceToPlane = simd_dot(toGrid, forward)
            if distanceToPlane <= 0 || distanceToPlane > farClip {
                continue
            }

            // Project onto camera plane
            let rightOffset = simd_dot(toGrid, right)
            let upOffset = simd_dot(toGrid, up)

            // Calculate frustum dimensions at this distance
            let frustumWidth = 2.0 * distanceToPlane * tan(horizontalFOV / 2.0)
            let frustumHeight = 2.0 * distanceToPlane * tan(verticalFOV / 2.0)

            // Check if within frustum
            if abs(rightOffset) <= frustumWidth/2 && abs(upOffset) <= frustumHeight/2 {
                var newTransform = origin
                newTransform.columns.3 = simd_float4(gridPosition.x, gridPosition.y, origin.columns.3.z, 1)
                
                let node = createPlaneNode(color: .red)
                node.simdTransform = newTransform
                sceneView.scene.rootNode.addChildNode(node)
                placedPositions.insert(gridPosition)
                visibleNodes[gridPosition] = node
            }
        }
    }
    
    private func createPlaneNode(color: UIColor) -> SCNNode {
        let planeGeometry = SCNPlane(width: CGFloat(PLANE_SIZE.x),
                                   height: CGFloat(PLANE_SIZE.y))
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        planeGeometry.materials = [planeMaterial]
        return SCNNode(geometry: planeGeometry)
    }
    
    private func updateVisiblePlanes(frame: ARFrame) {
        let camera = frame.camera
        let aspectRatio = Float(sceneView.bounds.width / sceneView.bounds.height)
        let frustumDims = getFrustumDimensions(fov: camera.fov,
                                             aspectRatio: aspectRatio,
                                             nearClip: nearClip,
                                             farClip: farClip)
        
        // Reset all nodes to red
        for node in visibleNodes.values {
            (node.geometry?.firstMaterial?.diffuse.contents as? UIColor) == .red
        }
        
        // Calculate camera forward and right vectors
        let cameraTransform = camera.transform
        let forward = -simd_normalize(simd_float3(cameraTransform.columns.2.x,
                                                cameraTransform.columns.2.y,
                                                cameraTransform.columns.2.z))
        let right = simd_normalize(simd_float3(cameraTransform.columns.0.x,
                                             cameraTransform.columns.0.y,
                                             cameraTransform.columns.0.z))
        let up = simd_cross(forward, right)
        
        // Check each placed position
        for position in placedPositions {
            guard let node = visibleNodes[position] else { continue }
            
            // Get vector from camera to plane
            let planePos = simd_float3(position.x, position.y, origin?.columns.3.z ?? 0)
            let toPlane = planePos - simd_float3(cameraTransform.columns.3.x,
                                               cameraTransform.columns.3.y,
                                               cameraTransform.columns.3.z)
            
            // Check if plane is in front of camera
            let distanceToPlane = simd_dot(toPlane, forward)
            if distanceToPlane <= 0 { continue }
            
            // Project onto camera plane
            let rightOffset = simd_dot(toPlane, right)
            let upOffset = simd_dot(toPlane, up)
            
            // Calculate frustum dimensions at this distance
            let frustumWidth = lerp(frustumDims.near.x, frustumDims.far.x,
                                  fraction: (distanceToPlane - nearClip) / (farClip - nearClip))
            let frustumHeight = lerp(frustumDims.near.y, frustumDims.far.y,
                                   fraction: (distanceToPlane - nearClip) / (farClip - nearClip))
            
            // Check if within frustum
            if abs(rightOffset) <= frustumWidth / 2 && abs(upOffset) <= frustumHeight / 2 {
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            }
        }
    }
    
    private func lerp(_ a: Float, _ b: Float, fraction: Float) -> Float {
        return a + (b - a) * fraction
    }
}

extension UnsafeMutablePointer {
    func valueAt(x: Int, y: Int, rowWidth: Int) -> Pointee {
        let centerIndex = y * rowWidth + x
        return self[centerIndex]
    }
}

extension CVPixelBuffer {
    var size: CGSize {
        CGSize(
            width: CVPixelBufferGetWidth(self),
            height: CVPixelBufferGetHeight(self)
        )
    }
}

extension ARCamera {
    var fov: simd_float2 {
        // Calculate FOV in radians
        let focalLengthX = intrinsics[0][0]
        let focalLengthY = intrinsics[1][1]
        let imageWidth = Float(imageResolution.width)
        let imageHeight = Float(imageResolution.height)
        
        let horizontalFOV = 2 * atan(imageWidth / (2 * focalLengthX))
        let verticalFOV = 2 * atan(imageHeight / (2 * focalLengthY))
        
        return simd_float2(horizontalFOV, verticalFOV)
    }
}
