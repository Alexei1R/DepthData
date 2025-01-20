import Foundation
import ARKit

enum SDK {
    func initialize(token: String) {}
}

let CYLINDER_RADIUS = 0.03
let OVERLAP_VALUE : Float = 1.1

enum ScanningEvent {
    case saveImage(UIImage, ARFrame)
    case captureAngle
}

public class ScanningViewController: UIViewController, ARSCNViewDelegate {

    let sceneView = ARSCNView()

    var origin: simd_float4x4?

    var settings = SDKEnvironment.shared.localStorage.appSettings

    var onEvent: ((ScanningEvent) -> Void)?

    private var placedPositions: Set<SIMD2<Float>> = []

    private let nearClip: Float = 0.01  // 1cm
    private let farClip: Float = 5.0    // 5m
    private var visibleNodes: [SIMD2<Float>: SCNNode] = [:]

    public override func viewDidLoad() {
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
        let planeGeometry = SCNPlane(
            width: settings!.camera!.shelfCoverageCellSize,
            height: settings!.camera!.shelfCoverageCellSize
        )
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


extension ScanningViewController: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let origin else {
            if let originPoint = computeOriginPoint(frame: frame) {
                self.origin = originPoint
                drawPlane(transform: originPoint, color: .blue)
            }
            return
        }

        let camera = frame.camera
        let cameraTransform = camera.transform
        
        // Get camera position and orientation vectors
        let cameraPos = cameraTransform.columns.3.xyz
        let forward = -simd_normalize(cameraTransform.columns.2.xyz)
        
        // Calculate a single distance that intersects our plane
        let originInverse = simd_inverse(origin)
        let cameraInPlaneSpace = (originInverse * simd_float4(cameraPos, 1)).xyz
        let forwardInPlaneSpace = simd_normalize((originInverse * simd_float4(forward, 0)).xyz)
        
        // Since our plane is at z=0 in plane space, calculate intersection distance
        // using the similar triangles formed by the camera angle
        let distanceToPlane = abs(cameraInPlaneSpace.z / forwardInPlaneSpace.z)
        
        // Calculate frustum dimensions at the intersection distance
        let fov = camera.fov
        let frustumHeight = 2.0 * distanceToPlane * tan(fov.y / 2.0)
        let frustumWidth = 2.0 * distanceToPlane * tan(fov.x / 2.0)
        
        // Calculate the four corners of the frustum at the intersection
        let right = simd_normalize(simd_cross(forward, simd_float3(0, 1, 0)))
        let up = simd_normalize(simd_cross(right, forward))

        // Adjust corner calculation to account for perspective
        let halfWidth = frustumWidth / 2
        let halfHeight = frustumHeight / 2
        let center = cameraPos + forward * distanceToPlane

        let cornersWorld: [simd_float3] = [
            center + (-right * halfWidth + up * halfHeight),    // top-left (0)
            center + (right * halfWidth + up * halfHeight),     // top-right (1)
            center + (right * halfWidth - up * halfHeight),     // bottom-right (2)
            center + (-right * halfWidth - up * halfHeight)     // bottom-left (3)
        ]

        // Project corners to plane space
        let cornersPlane = cornersWorld.map { worldPos -> simd_float2 in
            let planePos = (originInverse * simd_float4(worldPos, 1)).xyz
            return simd_float2(planePos.x, planePos.y)
        }
        
        // Find bounds of the projected quadrilateral
        let gridSpacingX = Float(settings!.camera!.shelfCoverageCellSize) * OVERLAP_VALUE
        let gridSpacingY = Float(settings!.camera!.shelfCoverageCellSize) * OVERLAP_VALUE
        
        let minX = cornersPlane.map(\.x).min()! - gridSpacingX
        let maxX = cornersPlane.map(\.x).max()! + gridSpacingX
        let minY = cornersPlane.map(\.y).min()! - gridSpacingY
        let maxY = cornersPlane.map(\.y).max()! + gridSpacingY
        
        let startX = round(minX / gridSpacingX) * gridSpacingX
        let endX = round(maxX / gridSpacingX) * gridSpacingX
        let startY = round(minY / gridSpacingY) * gridSpacingY
        let endY = round(maxY / gridSpacingY) * gridSpacingY
        
        var gridPositionsToCheck: Set<SIMD2<Float>> = []
        
        // Add potential grid positions
        var x = startX
        while x <= endX {
            var y = startY
            while y <= endY {
                let gridPosition = SIMD2<Float>(x, y)
                
                // Check all four corners of the grid cell
                let cellCorners = [
                    SIMD2<Float>(x - gridSpacingX/2, y - gridSpacingY/2),  // bottom-left
                    SIMD2<Float>(x + gridSpacingX/2, y - gridSpacingY/2),  // bottom-right
                    SIMD2<Float>(x - gridSpacingX/2, y + gridSpacingY/2),  // top-left
                    SIMD2<Float>(x + gridSpacingX/2, y + gridSpacingY/2)   // top-right
                ]
                
                // Check if all corners are inside the projected quadrilateral
                let allCornersInside = cellCorners.allSatisfy { corner in
                    isPointInQuadrilateral(point: corner, corners: cornersPlane)
                }
                
                if allCornersInside {
                    gridPositionsToCheck.insert(gridPosition)
                }
                
                y += gridSpacingY
            }
            x += gridSpacingX
        }

        let newCells = findNewCells(gridPositionsToCheck, origin: origin, forward: forward, cameraPos: cameraPos, fov: fov, right: right, up: up)

        // Upload image if needed
        if Double(newCells.count) > Double(gridPositionsToCheck.count) * settings!.camera!.shelfCoverageMinRatio {
            sendUploadImageEvent(frame: frame)

            newCells.forEach { (gridPosition, transform) in
                let node = createPlaneNode(color: .red)
                node.simdTransform = transform
                sceneView.scene.rootNode.addChildNode(node)
                placedPositions.insert(gridPosition)
                visibleNodes[gridPosition] = node
            }
        }
    }

    private func findNewCells(
        _ gridPositionsToCheck: [simd_float2],
        origin: simd_float4x4,
        forward: simd_float3,
        cameraPos: simd_float3,
        fov: simd_float2,
        right: simd_float3,
        up: simd_float3
    ) -> [(cell: simd_float2, transform: simd_float4x4)] {
        gridPositionsToCheck.reduce(into: [(SIMD2<Float>, simd_float4x4)]()) { cells, gridPosition in
            if placedPositions.contains(gridPosition) { return }

            let localToWorld = origin
            let localPos = simd_float3(gridPosition.x, gridPosition.y, 0)

            let worldPos = simd_float3(
                localToWorld.columns.0.x * localPos.x + localToWorld.columns.1.x * localPos.y + localToWorld.columns.3.x,
                localToWorld.columns.0.y * localPos.x + localToWorld.columns.1.y * localPos.y + localToWorld.columns.3.y,
                localToWorld.columns.0.z * localPos.x + localToWorld.columns.1.z * localPos.y + localToWorld.columns.3.z
            )

            let toGrid = worldPos - cameraPos
            let distanceToPlane = simd_dot(toGrid, forward)
            if distanceToPlane <= nearClip || distanceToPlane > farClip { return }

            let rightOffset = simd_dot(toGrid, right)
            let upOffset = simd_dot(toGrid, up)

            let horizontalAngle = abs(atan2(rightOffset, distanceToPlane))
            let verticalAngle = abs(atan2(upOffset, distanceToPlane))

            // Check if point is within FOV
            if horizontalAngle <= fov.x / 2 && verticalAngle <= fov.y / 2 {
                var transform = origin
                transform.columns.3 = simd_float4(worldPos, 1)
                cells += [(gridPosition, transform)]
            }
        }
    }

    private func sendUploadImageEvent(frame: ARFrame) {
        let image = UIImage(ciImage: CIImage(cvPixelBuffer: frame.capturedImage))
        onEvent?(.saveImage(image, frame))
        SDKEnvironment.shared.imageSevice.uploadImageToFirebase(image: image, arFrame: frame)
    }

    private func createPlaneNode(color: UIColor) -> SCNNode {
        let planeGeometry = SCNPlane(
            width: CGFloat(settings!.camera!.shelfCoverageCellSize),
            height: CGFloat(settings!.camera!.shelfCoverageCellSize)
        )
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        planeGeometry.materials = [planeMaterial]
        return SCNNode(geometry: planeGeometry)
    }

    private func lerp(_ a: Float, _ b: Float, fraction: Float) -> Float {
        return a + (b - a) * fraction
    }

    private func isPointInQuadrilateral(point: SIMD2<Float>, corners: [SIMD2<Float>]) -> Bool {
        return isPointInTriangle(point: point, p1: corners[0], p2: corners[1], p3: corners[2]) ||
               isPointInTriangle(point: point, p1: corners[0], p2: corners[2], p3: corners[3])
    }

    // barycentric check
    private func isPointInTriangle(point: SIMD2<Float>, p1: SIMD2<Float>, p2: SIMD2<Float>, p3: SIMD2<Float>) -> Bool {
        let denominator = (p2.y - p3.y) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.y - p3.y)
        let a = ((p2.y - p3.y) * (point.x - p3.x) + (p3.x - p2.x) * (point.y - p3.y)) / denominator
        let b = ((p3.y - p1.y) * (point.x - p3.x) + (p1.x - p3.x) * (point.y - p3.y)) / denominator
        let c = 1 - a - b

        return a >= 0 && a <= 1 && b >= 0 && b <= 1 && c >= 0 && c <= 1
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

extension simd_float4 {
    var xyz: simd_float3 {
        simd_float3(x: x, y: y, z: z)
    }
}
