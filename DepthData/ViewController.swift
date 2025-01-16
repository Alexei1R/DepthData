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
        
        // Get current camera position
        let currentPos = frame.camera.transform.columns.3
        
        // Calculate separate grid spacing for X and Y based on their respective dimensions
        let gridSpacingX = PLANE_SIZE.x * OVERLAP_VALUE
        let gridSpacingY = PLANE_SIZE.y * OVERLAP_VALUE
        
        // Calculate the closest grid position
        let relativeX = currentPos.x - origin.columns.3.x
        let relativeY = currentPos.y - origin.columns.3.y
        
        let centerX = round(relativeX / gridSpacingX) * gridSpacingX
        let centerY = round(relativeY / gridSpacingY) * gridSpacingY
        
        // Calculate target position
        let targetX = origin.columns.3.x + centerX
        let targetY = origin.columns.3.y + centerY
        
        let gridPosition = float2(targetX, targetY)
        
        // Define position tolerance
        let tolerance: Float = 0.001
        
        // Check if a plane already exists at this position
        let exists = placedPositions.contains { existingPos in
            abs(existingPos.x - gridPosition.x) < tolerance &&
            abs(existingPos.y - gridPosition.y) < tolerance
        }
        
        // Only place a new plane if one doesn't exist at this position
        if !exists {
            var newTransform = origin
            newTransform.columns.3 = simd_float4(
                targetX,
                targetY,
                origin.columns.3.z,
                1
            )
            
            drawPlane(transform: newTransform, color: .red)
            placedPositions.insert(gridPosition)
        }
        
        
        
        
        //Now chech if a 
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
