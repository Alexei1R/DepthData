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
        let cameraPos = simd_float3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        let forward = -simd_normalize(
            simd_float3(
                cameraTransform.columns.2.x,
                cameraTransform.columns.2.y,
                cameraTransform.columns.2.z
            )
        )
        let right = simd_normalize(
            simd_float3(
                cameraTransform.columns.0.x,
                cameraTransform.columns.0.y,
                cameraTransform.columns.0.z
            )
        )
        let up = simd_normalize(
            simd_float3(
                cameraTransform.columns.1.x,
                cameraTransform.columns.1.y,
                cameraTransform.columns.1.z
            )
        )

        let fov = camera.fov
        let horizontalFOV = fov.x
        let verticalFOV = fov.y

        let distances: [Float] = [nearClip, farClip / 2, farClip]
        var gridPositionsToCheck: Set<SIMD2<Float>> = []

        for distance in distances {
            let frustumHeight = 2.0 * distance * tan(verticalFOV / 2.0)
            let frustumWidth = 2.0 * distance * tan(horizontalFOV / 2.0)

            let cornersInCameraSpace: [simd_float3] = [
                // Top left
                cameraPos + forward * distance - right * (frustumWidth / 2) + up * (frustumHeight / 2),
                // Top right
                cameraPos + forward * distance + right * (frustumWidth / 2) + up * (frustumHeight / 2),
                // Bottom left
                cameraPos + forward * distance - right * (frustumWidth / 2) - up * (frustumHeight / 2),
                // Bottom right
                cameraPos + forward * distance + right * (frustumWidth / 2) - up * (frustumHeight / 2)
            ]

            let gridSpacingX = Float(settings!.camera!.shelfCoverageCellSize) * OVERLAP_VALUE
            let gridSpacingY = Float(settings!.camera!.shelfCoverageCellSize) * OVERLAP_VALUE

            let originInverse = simd_inverse(origin)
            let corners = cornersInCameraSpace.map { worldPos -> simd_float3 in
                let worldPoint = simd_float4(worldPos.x, worldPos.y, worldPos.z, 1)
                let localPoint = originInverse * worldPoint
                return simd_float3(localPoint.x, localPoint.y, localPoint.z)
            }

            let minX = corners.map(\.x).min()! - gridSpacingX
            let maxX = corners.map(\.x).max()! + gridSpacingX
            let minY = corners.map(\.y).min()! - gridSpacingY
            let maxY = corners.map(\.y).max()! + gridSpacingY

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

        let newCells = gridPositionsToCheck.reduce(into: [(SIMD2<Float>, simd_float4x4)]()) { cells, gridPosition in
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
            if horizontalAngle <= horizontalFOV / 2 && verticalAngle <= verticalFOV / 2 {
                var transform = origin
                transform.columns.3 = simd_float4(worldPos, 1)
                cells += [(gridPosition, transform)]
            }
        }

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
