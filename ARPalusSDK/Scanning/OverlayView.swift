//
//  OverlayView.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import SwiftUI

final class OverlayViewModel: ObservableObject {
    @Published var isCalibrated = false
    @Published var isScanning = false
    @Published var text: String?
}

struct Overlay: View {

    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack {
            if let text = viewModel.text {
                Text(text)
                    .font(.title)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.regularMaterial)
                    )
            }
            Spacer()
            if viewModel.isCalibrated && !viewModel.isScanning {
                Button(action: {
                    viewModel.isScanning = true
                }, label: {
                    Text("Start Scanning")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue)
                        )
                })
            }
        }
    }
}
