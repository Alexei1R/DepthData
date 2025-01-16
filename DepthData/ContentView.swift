//
//  ContentView.swift
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

import SwiftUI
import MetalKit
import ARKit

struct ArpalusMain: View {
    @State private var distance: Float = 0
    
    var body: some View {
        ZStack {
            if !ARWorldTrackingConfiguration.supportsFrameSemantics([.sceneDepth, .smoothedSceneDepth]) {
                Text("Unsupported Device: This app requires the LiDAR Scanner to access the scene's depth.")
                    .padding()
                    .multilineTextAlignment(.center)
            } else {
                ARView()
            }
        }
    }
}

struct ARView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiView: UIViewControllerType, context: Context) {

    }
}

#Preview {
    ArpalusMain()
}
