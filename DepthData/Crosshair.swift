//
//  Crosshair.swift
//  DepthData
//
//  Created by Iuri Fazli on 15.01.2025.
//

import Foundation
import SwiftUI

struct Crosshair: View {
    var body: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 20)
            
            // Horizontal line
            Rectangle()
                .fill(Color.white)
                .frame(width: 20, height: 2)
        }
        .shadow(color: .black.opacity(0.5), radius: 2)
    }
}

#Preview {
    Crosshair()
        .preferredColorScheme(.dark)
}
