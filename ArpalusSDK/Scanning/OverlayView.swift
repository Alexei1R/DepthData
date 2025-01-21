//
//  OverlayView.swift
//  ArpalusSample
//
//  Created by Alex Culeva on 20.01.2025.
//

import SwiftUI
import Combine

final class OverlayViewModel: ObservableObject {
    @Published var isCalibrated = false
    @Published var isScanning = false
    @Published var text: String?

    private var imageService: ImageService
    private var cancellables = Set<AnyCancellable>()

    init(imageService: ImageService) {
        self.imageService = imageService
        imageService.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.isScanning = newValue
            }
            .store(in: &cancellables)
    }

    func start() {
        imageService.setupUploanding()
    }

    func stop() {
        imageService.stopUploading()
    }
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
                    viewModel.start()
                }, label: {
                    Text("Start Scanning")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 44)
                                .stroke(style: .init(lineWidth: 4))
                                .foregroundStyle(.white)
                                .overlay(content: {
                                    RoundedRectangle(cornerRadius: 44)
                                        .padding(2)
                                        .foregroundStyle(.blue)
                                })

                        )
                })
            } else if viewModel.isCalibrated && viewModel.isScanning{
                Button {
                    viewModel.stop()
                } label: {
                    Circle()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(.white)
                        .opacity(0.53)
                        .overlay {
                            Circle()
                                .frame(width: 86, height: 86)
                                .foregroundStyle(.white)
                                .opacity(0.4)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(.white)
                                }
                        }
                }

            }
        }
        .padding(.horizontal, 24)
    }
}
