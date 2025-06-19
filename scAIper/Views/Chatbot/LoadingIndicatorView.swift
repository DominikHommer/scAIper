//
//  LoadingIndicatorView.swift
//  scAIper
//
//  Created by Dominik Hommer on 07.04.25.
//

import SwiftUI

/// A simple loading indicator view that displays animated dots.
/// The number of dots cycles from 1 to 3 over time to simulate loading feedback.
struct LoadingIndicatorView: View {
    
    /// Tracks the current number of dots shown in the animation.
    @State private var dotCount = 0
    
    /// A repeating timer that updates the dot count every 0.5 seconds.
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            // Render one circle per current dot count
            ForEach(0..<dotCount, id: \.self) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
            }
        }
        // Update the dot count every time the timer fires
        .onReceive(timer) { _ in
            dotCount = (dotCount % 3) + 1
        }
    }
}

