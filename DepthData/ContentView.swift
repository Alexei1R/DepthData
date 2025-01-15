//
//  ContentView.swift
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

import SwiftUI
import MetalKit
import ARKit

struct ArpausMain: View {
    @StateObject private var arSession = ARSessionManager()
    @State private var distance: Float = 0
    
    var body: some View {
        ZStack {
            if !ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .smoothedSceneDepth]) {
                Text("Unsupported Device: This app requires the LiDAR Scanner to access the scene's depth.")
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                MetalTextureView(texture: arSession.depthTexture, distance: $distance)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        arSession.startSession()
                    }
                
                // Crosshair
                Crosshair()
                
                // Distance overlay
                VStack {
                    Spacer()
                    Text(String(format: "Distance: %.2f meters", distance))
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

#Preview {
    ArpausMain()
}

class ARSessionManager: NSObject, ObservableObject, ARSessionDelegate {
    private let session = ARSession()
    @Published var depthTexture: MTLTexture?
    
    override init() {
        super.init()
        session.delegate = self
    }
    
    func startSession() {
        guard ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth]) else {
            print("Scene depth is not supported on this device")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        
        // Force portrait video format
        if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats
            .first(where: { $0.imageResolution.height > $0.imageResolution.width }) {
            configuration.videoFormat = videoFormat
        }
        
        DispatchQueue.main.async {
            self.session.run(configuration)
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let depthMap = frame.sceneDepth?.depthMap else { return }
        
        depthTexture = TextureCreator.createTexture(
            from: depthMap,
            device: MetalEnvironment.shared.device
        )
    }
}
