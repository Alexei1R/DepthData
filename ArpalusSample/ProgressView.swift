//
//  ProgressView.swift
//  ArpalusSample
//
//  Created by Александр Новиков on 21.01.2025.
//

import SwiftUI

struct ProgressView: View {

    @Binding var progress: Double

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                createLogo()
                    .padding(.top, 82)
                createContent()
                    .padding(.top, 64)
                createProgressBar()
                    .padding(.top, 34)
                Spacer()
            }
        }
    }
}

#Preview {
    ProgressView(progress: .constant(0))
}

private extension ProgressView {
    func createLogo() -> some View {
        Image(.arpalusFullLogo)
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 41)
    }

    func createContent() -> some View {
        VStack {
            Image(.progressContent)
            Text("Welcome to arpalus")
            Text("Updating")
        }
    }

    func createProgressBar() -> some View {
        VStack {
            RoundedRectangle(cornerRadius: 65)
                .stroke(lineWidth: 1)
                .foregroundStyle(.aliceBlue)
                .frame(width: 290, height: 20)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 51)
                        .frame(width: 278 * progress, height: 11)
                        .padding(.horizontal, 6)
                        .foregroundStyle(.arpalusBlue)
                }
//                .shadow(color: .black, radius: 1, x: 0, y: 8)

            Text("\(Int(progress * 100))%")
        }
    }
}
