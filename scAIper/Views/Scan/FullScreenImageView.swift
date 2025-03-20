//
//  FullScreenImageView.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//


import SwiftUI

struct FullScreenImageView: View {
    var image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .onTapGesture {
                    dismiss()
                }
        }
    }
}

#Preview {
    FullScreenImageView(image: UIImage(named: "exampleImage") ?? UIImage())
}