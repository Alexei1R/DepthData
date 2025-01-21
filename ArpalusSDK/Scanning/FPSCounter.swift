//
//  FPSCounter.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 21.01.2025.
//

import ARKit

class FPSCounter {
    // Configuration
    let frameRange = 60
    var maxAcceptableFPS = 20

    // FPS Statistics
    private(set) public var averageFPS: Int = 0
    private(set) public var highestFPS: Int = 0
    private(set) public var lowestFPS: Int = 0
    private var previousLowestFPS: Int = 0

    // Buffer management
    private var fpsBuffer: [Int]
    private var fpsBufferIndex = 0

    private var lastFrameTime: TimeInterval = -1

    init() {
        self.fpsBuffer = [Int](repeating: 0, count: frameRange)
    }

    private func updateBuffer(_ frame: ARFrame) {
        let deltaTime = frame.timestamp - lastFrameTime
        lastFrameTime = frame.timestamp

        let fps = Int(1.0 / deltaTime)
        fpsBuffer[fpsBufferIndex] = fps
        fpsBufferIndex += 1
        if fpsBufferIndex >= frameRange {
            fpsBufferIndex = 0
        }
    }

    private func calculateFPS() {
        var sum = 0
        var highest = 0
        var lowest = Int.max

        for fps in fpsBuffer {
            sum += fps
            highest = max(highest, fps)
            lowest = min(lowest, fps)
        }

        averageFPS = Int(Float(sum) / Float(frameRange))
        highestFPS = highest
        lowestFPS = lowest

        if lowestFPS < maxAcceptableFPS && lowestFPS != previousLowestFPS {
            previousLowestFPS = lowestFPS
            print("Warning: Low FPS detected: \(lowestFPS)")
        }
    }

    func update(_ frame: ARFrame) {
        if lastFrameTime == -1 {
            lastFrameTime = frame.timestamp
            return
        }
        updateBuffer(frame)
        calculateFPS()
    }
}

