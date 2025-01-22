import Foundation
import ARKit
import SwiftUI

let OVERLAP_VALUE : Float = 1.1

public class ScanningViewController: UIViewController, ARSCNViewDelegate {

    let sceneView = ARSCNView()

    var settings = SDKEnvironment.shared.localStorage.appSettings!
    lazy var calibrator = Calibrator(camera: settings.camera, vision: settings.vision)
    let motionTracker = MotionTracker()
    var overlayViewModel: OverlayViewModel!
    let fpsCounter = FPSCounter()

    var frameNumber = 0
    var imgCount = 0

    var origin: simd_float4x4?
    private var placedPositions: Set<SIMD2<Float>> = []

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
//            view.centerYAnchor.constraint(equalTo: sceneView.centerYAnchor),
//            sceneView.heightAnchor.constraint(equalTo: sceneView.widthAnchor, multiplier: 1.3333)
        ])

        createOverlay()

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.preferredFramesPerSecond = 60
        sceneView.automaticallyUpdatesLighting = true
        sceneView.session.delegate = self

        let configuration = ARWorldTrackingConfiguration()
        
        configuration.worldAlignment = .gravity
        configuration.isLightEstimationEnabled = true
        
        let frameSemantics: ARConfiguration.FrameSemantics = [.sceneDepth, .smoothedSceneDepth]
        if ARWorldTrackingConfiguration.supportsFrameSemantics(frameSemantics) {
            configuration.frameSemantics = frameSemantics
        }
        let bestFormat = CameraConfig.bestCameraConfig(
            settings: settings.camera,
            formats: ARWorldTrackingConfiguration.supportedVideoFormats
        )
        bestFormat.map { configuration.videoFormat = $0 }
        sceneView.debugOptions = [.renderAsWireframe, SCNDebugOptions(rawValue: 2048)]


        sceneView.session.run(configuration)
    }

    private func createOverlay() {
        overlayViewModel = OverlayViewModel(imageService: SDKEnvironment.shared.imageSevice)
        let overlay = Overlay(viewModel: overlayViewModel)

        let vc = UIHostingController(rootView: overlay)
        vc.willMove(toParent: self)
        view.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.backgroundColor = .clear
        addChild(vc)
        vc.didMove(toParent: self)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: vc.view.topAnchor),
            view.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            view.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
        ])
        view.bringSubviewToFront(vc.view)
    }

    private func drawOrigin(transform: simd_float4x4) {
        guard true /*settings.debug!.debugPlaneOrigin*/ else { return }
        let sphere = SCNSphere(radius: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        sphere.materials = [material]

        let node = SCNNode(geometry: sphere)
        node.simdTransform = transform
        

        sceneView.scene.rootNode.addChildNode(node)
    }

    private func tryCalibrate(_ frame: ARFrame) {
        let calibrationResult = calibrator.calibrateOrigin(frame: frame)
        switch calibrationResult {
        case .invalidPitch:
            overlayViewModel.text = "Invalid pitch"
        case .invalidRoll:
            overlayViewModel.text = "Invalid roll"
        case .cannotComputeOrigin:
            break
        case .tooClose:
            overlayViewModel.text = "Move further"
        case .inProgress:
            print("Calibrating")
        case .calibrated(let origin):
            overlayViewModel.isCalibrated = true
            self.origin = origin
            drawOrigin(transform: origin)
        }
    }

    private func isValidAngle(frame: ARFrame) -> Bool {
        guard let origin else {
            return false
        }

        let camera = frame.camera
        let cameraTransform = camera.transform

        // Get camera orientation relative to origin
        let relativeTransform = simd_inverse(origin) * cameraTransform
        let eulerAngles = relativeTransform.eulerAngles

        // Convert to degrees
        let pitchDegrees = eulerAngles.cameraPitch
        let yawDegrees = abs(eulerAngles.y * 180 / .pi)
        let rollDegrees = eulerAngles.cameraRoll

//        print("Pitch: \(Int(pitchDegrees)); Yaw: \(Int(yawDegrees)); Roll: \(Int(rollDegrees))")
    

        if Double(pitchDegrees) > settings.camera.captureAnglePitch {
            overlayViewModel.text = "Pitch to shelf"
            return false
        }

        if Double(yawDegrees) > settings.camera.captureAngleYaw {
            overlayViewModel.text = "Yaw to shelf"
            return false
        }

        if Double(rollDegrees) > settings.camera.captureAngleRoll {
            overlayViewModel.text = "Roll to shelf"
            return false
        }

        return true
    }

    private func isValidDistance(_ distance: Double) -> Bool {
        let isTooClose = distance < settings.vision.minDetectionDistance || distance < settings.vision.minStartingDistance
        if isTooClose && settings.camera.tooCloseToShelfWarning {
            overlayViewModel.text = "Too Close to Shelf"
            return false
        }
        if settings.camera.tooFarToShelfWarning && distance > settings.vision.maxDetectionDistance {
            overlayViewModel.text = "Too Far to Shelf"
            return false
        }
        return true
    }

    private func isValidSpeed(_ frame: ARFrame) -> Bool {
        motionTracker.update(frame: frame)
        if motionTracker.acceleration > settings.camera.maxMotionAccelerationSpeed {
            overlayViewModel.text = "Move slower"
            return false
        }
        if motionTracker.angularAcceleration > settings.camera.maxMotionAngularAccelerationSpeed {
            overlayViewModel.text = "Rotate slower"
            return false
        }
        return true
    }

    private func buildCameraInfo(_ frame: ARFrame) -> CameraInfo {
        let light = frame.lightEstimate
        // this will be nil
        let directionalLight = light as? ARDirectionalLightEstimate
        let sphericalHarmonics = directionalLight
            .flatMap { try? JSONDecoder().decode([[Double]].self, from: $0.sphericalHarmonicsCoefficients) }
        return CameraInfo(
            projectionMatrix: frame.camera.projectionMatrix.codableMatrix,
            displayMatrix: .init(matrix: []),  // This appears to be unused/empty
            exposureDuration: frame.camera.exposureDuration,
            exposureOffset: Double(frame.camera.exposureOffset),
            focalLength: .init(
                x: Double(frame.camera.intrinsics[0][0]),
                y: Double(frame.camera.intrinsics[1][1])
            ),
            principalPoint: .init(
                x: Double(frame.camera.intrinsics[2][0]),
                y: Double(frame.camera.intrinsics[2][1])
            ),
            resolution: .init(
                x: Int(frame.camera.imageResolution.height),
                y: Int(frame.camera.imageResolution.width)
            ),
            averageBrightness: 0,
            averageColorTemperature: light.map { Double($0.ambientColorTemperature) } ?? 0,
            averageIntensityInLumens: light.map { Double($0.ambientIntensity) } ?? 0,
            mainLightIntensityLumens: (light as? ARDirectionalLightEstimate)
                .map { Double($0.primaryLightIntensity) } ?? 0,
            averageMainLightBrightness: 0,
            colorCorrection: .init(r: 1, g: 1, b: 1, a: 1),
            mainLightColor: .init(r: 1, g: 1, b: 1, a: 1),
            mainLightDirection: .init(
                x: Double(directionalLight?.primaryLightDirection.x ?? 0),
                y: Double(directionalLight?.primaryLightDirection.y ?? 0),
                z: Double(directionalLight?.primaryLightDirection.z ?? 0)
            ),
            ambientSphericalHarmonics: .init(coefficients: sphericalHarmonics ?? [])
        )
    }

    private func buildImageMetadata(
        _ frame: ARFrame,
        origin: simd_float4x4,
        image: UIImage
    ) -> ImageMetadata {
        let cameraInfo = (try? JSONEncoder().encode(buildCameraInfo(frame))).flatMap {
            String(data: $0, encoding: .utf8)
        } ?? ""
        let camTransform = frame.camera.transform
        let camTransformString = buildCameraPoseString(
            position: camTransform.columns.3.xyz,
            rotation: simd_quatf(camTransform)
        )
        let originString = buildCameraPoseString(
            position: origin.columns.3.xyz,
            rotation: simd_quatf(origin)
        )

        return ImageMetadata(
            cameraInfo: cameraInfo,
            cameraTransformBefore: camTransformString,
            cameraTransformBeforeOriginal: camTransformString,
            cameraTransformAfter: "",
            originCaptureTransform: originString,
            originDoneTransform: originString,
            timestamp: "\(frame.timestamp)",
            time: Date().timeIntervalSince1970,
            frameNumber: frameNumber,
            imgCount: imgCount,
            saveButtonUsed: false,
            imageWidth: Int(image.size.width),
            imageHeight: Int(image.size.height),
            averageFps: Double(fpsCounter.averageFPS),
            minFps: Double(fpsCounter.lowestFPS),
            velocity: Double(motionTracker.velocity),
            angularVelocity: Double(motionTracker.angularVelocity),
            acceleration: motionTracker.acceleration,
            angularAcceleration: motionTracker.angularAcceleration,
            frameResults: [],
            pointCloud: getPointCloudInViewport(frame).map { "\($0.x) \($0.y) \($0.z)" }
        )
    }

    private func getPointCloudInViewport(_ frame: ARFrame) -> [simd_float3] {
        frame.rawFeaturePoints?.points.filter { point in
            let projectedPoint = frame.camera.projectPoint(
                point,
                orientation: .portrait,
                viewportSize: frame.camera.imageResolution
            )

            return projectedPoint.x >= 0 && projectedPoint.x < frame.camera.imageResolution.width &&
               projectedPoint.y >= 0 && projectedPoint.y < frame.camera.imageResolution.height
        } ?? []
    }
}

extension ScanningViewController: ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        fpsCounter.update(frame)
        defer { frameNumber += 1 }
        overlayViewModel.text = nil
        guard let origin else {
            return tryCalibrate(frame)
        }
        guard overlayViewModel.isScanning else { return }
        guard isValidSpeed(frame), isValidAngle(frame: frame) else { return }

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

        guard isValidDistance(Double(distanceToPlane)) else { return }

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
            center + (-right * halfHeight - up * halfWidth),    // bottom-left (0)
            center + (-right * halfHeight + up * halfWidth),    // top-left (1)
            center + (right * halfHeight + up * halfWidth),     // top-right (2)
            center + (right * halfHeight - up * halfWidth)      // bottom-right (3)
        ]

        // Project corners to plane space
        let cornersPlane = cornersWorld.map { worldPos -> simd_float2 in
            let planePos = (originInverse * simd_float4(worldPos, 1)).xyz
            return simd_float2(planePos.x, planePos.y)
        }
        
        // Find bounds of the projected quadrilateral
        let gridSpacingX = Float(settings.camera.shelfCoverageCellsSize) * OVERLAP_VALUE
        let gridSpacingY = Float(settings.camera.shelfCoverageCellsSize) * OVERLAP_VALUE

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
                    SIMD2<Float>(x - gridSpacingX / 2, y - gridSpacingY / 2),  // bottom-left
                    SIMD2<Float>(x + gridSpacingX / 2, y - gridSpacingY / 2),  // bottom-right
                    SIMD2<Float>(x - gridSpacingX / 2, y + gridSpacingY / 2),  // top-left
                    SIMD2<Float>(x + gridSpacingX / 2, y + gridSpacingY / 2)   // top-right
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
//        sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        // Upload image if needed
        if Double(newCells.count) > Double(gridPositionsToCheck.count) * settings.camera.shelfCoverageMinRatio {
            let image = getScaledImage(buffer: frame.capturedImage)
            imgCount += 1
            SDKEnvironment.shared.imageSevice.saveImage(
                image,
                arFrame: frame,
                metadata: buildImageMetadata(frame, origin: origin, image: image)
            )

            newCells.forEach { (gridPosition, transform) in
                let node = createPlaneNode(color: .white)
                node.simdTransform = transform
                sceneView.scene.rootNode.addChildNode(node)
                placedPositions.insert(gridPosition)
                visibleNodes[gridPosition] = node
            }
        }
    }

    private func findNewCells(
        _ gridPositionsToCheck: Set<simd_float2>,
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

    private func getScaledImage(buffer: CVPixelBuffer) -> UIImage {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let image = CIImage(cvPixelBuffer: buffer).transformed(by: .init(rotationAngle: -.pi/2))
        guard settings.camera.lowerSaveResolution, Int(buffer.size.width) != settings.camera.saveResolutionWidth else {
            return UIImage(ciImage: image)
        }
        let scale = CGFloat(settings.camera.saveResolutionWidth) / buffer.size.height
        return UIImage(ciImage: image.transformed(by: .init(scaleX: scale, y: scale)))
    }

    private func createPlaneNode(color: UIColor) -> SCNNode {
        let planeGeometry = SCNPlane(
            width: CGFloat(settings.camera.shelfCoverageCellsSize),
            height: CGFloat(settings.camera.shelfCoverageCellsSize)
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

extension simd_float4x4 {
    var eulerAngles: simd_float3 {
        // X-Y-Z rotation order (pitch-yaw-roll)
        let x = asin(columns.0.z)
        let y = atan2(-columns.1.z, columns.2.z)
        let z = atan2(-columns.0.y, columns.0.x)
        return simd_float3(x, y, z)
    }
}
