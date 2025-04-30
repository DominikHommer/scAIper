//
//  LoadingIndicatorView.swift
//  scAIper
//
//  Created by Dominik Hommer on 07.04.25.
//
import SwiftUI

struct LoadingIndicatorView: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<dotCount, id: \.self) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
            }
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount % 3) + 1
        }
    }
}

