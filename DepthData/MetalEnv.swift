//
//  MetalEnv.swift
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

import Foundation
import Metal
import MetalKit

class MetalEnvironment {
    static let shared = MetalEnvironment()
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = try? device.makeDefaultLibrary() else {
            fatalError("Failed to create Metal environment")
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
    }
}
