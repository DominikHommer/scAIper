//
//  SplashScreenView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

/// A simple splash screen that animates the logo and transitions to the main view.
/// Displays the app name and logo, then navigates to `MainView` after a short delay.
struct SplashScreenView: View {
    
    /// Vertical offset for the logo animation.
    @State private var logoOffset: CGFloat = 300
    
    /// Indicates whether the splash screen is finished and should navigate to `MainView`.
    @State private var isActive = false

    var body: some View {
        if isActive {
            /// Main application view shown after the splash animation completes.
            MainView()
        } else {
            VStack {
                Spacer()

                /// App name displayed prominently on splash screen.
                Text("scAIper")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.black)
                    .padding()

                /// App logo with slide-in animation effect.
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .offset(y: logoOffset)
                    .onAppear {
                        /// Animate the logo into view.
                        withAnimation(.easeOut(duration: 1.5)) {
                            logoOffset = 0
                        }
                        /// Switch to main view after 2.5 seconds.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            isActive = true
                        }
                    }

                Spacer()
            }
            .background(Color.white.ignoresSafeArea())
        }
    }
}

#Preview {
    SplashScreenView()
}


