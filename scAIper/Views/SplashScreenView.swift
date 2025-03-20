//
//  SplashScreenView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoOffset: CGFloat = 300
    @State private var isActive = false

    var body: some View {
        if isActive {
            MainView()
        } else {
            VStack {
                Spacer()

                Text("scAIper")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.black)
                    .padding()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .offset(y: logoOffset)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.5)) {
                            logoOffset = 0
                        }
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


