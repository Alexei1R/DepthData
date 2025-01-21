import CoreMotion
import ARKit

class MotionTracker {

    private let motionManager = CMMotionManager()
    private var lastPosition: simd_float3?
    private var lastRotation: simd_quatf?
    private let updateInterval: TimeInterval = 1 / 60.0 // 60Hz updates

    private(set) var acceleration: Double = 0
    private(set) var angularAcceleration: Double = 0
    private(set) var velocity: Float = 0
    private(set) var angularVelocity: Float = 0

    init() {
        setupMotionManager()
    }

    deinit {
        stop()
    }

    private func setupMotionManager() {
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        
        motionManager.startDeviceMotionUpdates()
    }
    
    func update(frame: ARFrame)  {
        defer {
            lastPosition = frame.camera.transform.columns.3.xyz
            lastRotation = simd_quatf(frame.camera.transform)
        }
        guard let deviceMotion = motionManager.deviceMotion else {
            return reset()
        }

        let acc = deviceMotion.userAcceleration
        acceleration = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)

        let rotation = deviceMotion.rotationRate
        angularAcceleration = sqrt(rotation.x * rotation.x + rotation.y * rotation.y + rotation.z * rotation.z)

        let currentPosition = frame.camera.transform.columns.3.xyz
        if let lastPosition {
            velocity = simd_distance(lastPosition, currentPosition) / Float(updateInterval)
        }
        
        // Calculate rotation-based angular velocity
        let currentRotation = simd_quatf(frame.camera.transform)
        if let lastRotation {
            // Calculate angle between quaternions
            let dot = simd_dot(lastRotation, currentRotation)
            let angle = 2 * acos(min(1, max(-1, dot))) // Clamp dot product to [-1, 1]
            angularVelocity = angle / Float(updateInterval)
        }
    }

    private func reset() {
        lastRotation = nil
        lastPosition = nil
    }

    private func stop() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
} 
