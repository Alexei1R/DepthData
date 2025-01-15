//
//  MetalTextureViewDepth.swift
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

import SwiftUI
import MetalKit

// SwiftUI wrapper
struct MetalTextureView: UIViewRepresentable {
    var texture: MTLTexture?
    @Binding var distance: Float
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MetalTextureViewDepth(frame: .zero, device: MetalEnvironment.shared.device)
        mtkView.texture = texture
        mtkView.distanceCallback = { distance in
            self.distance = distance
        }
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        if let mtkView = uiView as? MetalTextureViewDepth {
            mtkView.updateTexture(texture)
        }
    }
}

// Original MTKView subclass
class MetalTextureViewDepth: MTKView, MTKViewDelegate {
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var currentTexturePointer: UnsafeMutableRawPointer?
    var texture: MTLTexture?
    var distanceCallback: ((Float) -> Void)?
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setupView()
        createPipelineState()
        createDefaultVertexBuffer()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        createPipelineState()
        createDefaultVertexBuffer()
    }
    
    func updateTexture(_ newTexture: MTLTexture?) {
        let newPointer: UnsafeMutableRawPointer?
        if let texture = newTexture {
            newPointer = Unmanaged.passUnretained(texture).toOpaque()
        } else {
            newPointer = nil
        }
        
        if newPointer != currentTexturePointer {
            texture = newTexture
            currentTexturePointer = newPointer
            updateVertexBuffer()
        }
    }
    
    private func setupView() {
        self.device = MetalEnvironment.shared.device
        self.colorPixelFormat = .bgra8Unorm
        self.contentScaleFactor = UIScreen.main.scale
        self.autoResizeDrawable = true
        self.contentMode = .scaleAspectFit
        self.delegate = self
        
        // Set clear color to black
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    }
    
    private func createPipelineState() {
        let library = MetalEnvironment.shared.library
        guard let vertexFunction = library.makeFunction(name: "texture_vertex_shader"),
              let fragmentFunction = library.makeFunction(name: "texture_fragment_shader") else {
            print("Failed to create shader functions")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try MetalEnvironment.shared.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    private func createDefaultVertexBuffer() {
        // Adjusted default texture coordinates to match the correct orientation
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-1, 1), texCoord: SIMD2<Float>(0, 0)),
            Vertex(position: SIMD2<Float>(-1, -1), texCoord: SIMD2<Float>(1, 0)),
            Vertex(position: SIMD2<Float>(1, 1), texCoord: SIMD2<Float>(0, 1)),
            Vertex(position: SIMD2<Float>(1, -1), texCoord: SIMD2<Float>(1, 1))
        ]
        
        vertexBuffer = device?.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Vertex>.stride,
            options: []
        )
    }
    
    func updateVertexBuffer() {
        guard let texture = texture else {
            createDefaultVertexBuffer()
            return
        }

        // Calculate aspect ratios
        let viewAspect = Float(bounds.width / bounds.height)
        let textureAspect = Float(texture.width) / Float(texture.height)

        // Calculate scaling factors to maintain aspect ratio
        var scaleX: Float = 1.0
        var scaleY: Float = 1.0

        if viewAspect > textureAspect {
            // View is wider than texture
            scaleX = textureAspect / viewAspect
        } else {
            // View is taller than texture
            scaleY = viewAspect / textureAspect
        }

        // Adjusted texture coordinates to correctly flip and map the texture
        let vertices: [Vertex] = [
            Vertex(position: SIMD2<Float>(-scaleX, scaleY), texCoord: SIMD2<Float>(0, 1)),   // Top left
            Vertex(position: SIMD2<Float>(-scaleX, -scaleY), texCoord: SIMD2<Float>(0, 0)),  // Bottom left
            Vertex(position: SIMD2<Float>(scaleX, scaleY), texCoord: SIMD2<Float>(1, 1)),    // Top right
            Vertex(position: SIMD2<Float>(scaleX, -scaleY), texCoord: SIMD2<Float>(1, 0))    // Bottom right
        ]

        vertexBuffer = device?.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Vertex>.stride,
            options: []
        )

        setNeedsDisplay()
    }


    func calculateCenterDistance() {
        guard let texture = texture else { return }
        
        // Get center pixel coordinates
        let centerX = texture.width / 2
        let centerY = texture.height / 2
        
        // Create a region for reading the center pixel
        let region = MTLRegion(origin: MTLOrigin(x: centerX, y: centerY, z: 0),
                             size: MTLSize(width: 1, height: 1, depth: 1))
        
        // Buffer to store the depth value
        var depthValue: Float = 0
        texture.getBytes(&depthValue,
                        bytesPerRow: MemoryLayout<Float>.size,
                        from: region,
                        mipmapLevel: 0)
        
        // Convert depth to meters and send via callback
        distanceCallback?(depthValue)
    }
    
    // MTKViewDelegate methods
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateVertexBuffer()
    }
    
    func draw(in view: MTKView) {
        // Calculate distance before rendering
        calculateCenterDistance()
        
        guard let currentDrawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = pipelineState,
              let vertexBuffer = vertexBuffer,
              let commandBuffer = MetalEnvironment.shared.commandQueue.makeCommandBuffer(),
              let texture = texture else {
            // Clear the view when no texture is available
            if let commandBuffer = MetalEnvironment.shared.commandQueue.makeCommandBuffer(),
               let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!) {
                renderEncoder.endEncoding()
                commandBuffer.present(view.currentDrawable!)
                commandBuffer.commit()
            }
            return
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
}

// Vertex structure matching the shader
struct Vertex {
    var position: SIMD2<Float>
    var texCoord: SIMD2<Float>
}
