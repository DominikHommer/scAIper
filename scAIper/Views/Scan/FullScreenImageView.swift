//
//  FullScreenImageView.swift
//  scAIper
//
//  Created by Dominik Hommer on 20.03.25.
//

import SwiftUI

/// A view that displays a given `UIImage` in full-screen mode with a black background.
/// Tapping the image will dismiss the view.
struct FullScreenImageView: View {
    
    /// The image to be displayed in full screen.
    var image: UIImage
    
    /// The environment dismiss action used to close the view when tapped.
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Black background filling the entire screen.
            Color.black.ignoresSafeArea()
            
            // Display the image scaled to fit within the screen.
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .onTapGesture {
                    // Dismiss the view when the image is tapped.
                    dismiss()
                }
        }
    }
}
