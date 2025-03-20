//
//  DocumentDetailView.swift
//  scAIper
//
//  Created by Dominik Hommer on 17.03.25.
//


import SwiftUI

struct DocumentDetailView: View {
    let document: Document

    var body: some View {
        VStack {
            Text(document.name)
                .font(.title)
                .padding()

            Text("Gescannt am: \(document.date, format: .dateTime.day().month().year())")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .navigationTitle("Dokument Details")
    }
}

#Preview {
    DocumentDetailView(document: Document(name: "Mietvertrag", date: Date()))
}
