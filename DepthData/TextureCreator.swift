//
//  TextureCreator.swift
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

import Foundation
import Metal
import CoreVideo

class TextureCreator {
    static func createTexture(from depthData: CVPixelBuffer, device: MTLDevice) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(depthData)
        let height = CVPixelBufferGetHeight(depthData)
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r32Float,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthData)
        let baseAddress = CVPixelBufferGetBaseAddress(depthData)
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: baseAddress!,
            bytesPerRow: bytesPerRow
        )
        
        return texture
    }
}
