//
//  DocumentType.swift
//  scAIper
//
//  Created by Dominik Hommer on 25.03.25.
//

import SwiftUI

/// Enum representing the different types of documents supported by scAIper.
/// Each case is codable, identifiable, and can be iterated over.
enum DocumentType: String, CaseIterable, Identifiable, Codable {
    case rechnung = "Rechnung"
    case bericht = "Bericht"
    case lohnzettel = "Lohnzettel"
    case vertrag = "Vertrag"
    case andere = "Andere"
    
    /// A unique identifier for each document type.
    var id: String { self.rawValue }
    
    /// System icon name associated with the document type.
    var icon: String {
        switch self {
        case .rechnung: return "doc.text"
        case .bericht: return "doc.plaintext"
        case .lohnzettel: return "eurosign.square"
        case .vertrag: return "doc.richtext"
        case .andere: return "doc.append"
        }
    }
    
    /// Color used to visually distinguish document types in the UI.
    var color: Color {
        switch self {
        case .rechnung: return .blue
        case .bericht: return .purple
        case .lohnzettel: return .orange
        case .vertrag: return .red
        case .andere: return .green
        }
    }
}

/// A tile view that visually represents a document type with icon and label.
struct DocumentTileView: View {
    /// The document type to display.
    var type: DocumentType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(type.color)
                    .clipShape(Circle())
                Spacer()
            }
            Text(type.rawValue)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
}

/// A view showing all available document types in a grid.
/// Tapping on a document type navigates to the document scanner.
struct DocumentGridView: View {

    /// The document type selected by the user.
    @State private var selectedDocument: DocumentType? = nil

    /// The navigation path for the stack-based navigation.
    @State private var path = NavigationPath()

    /// Defines a two-column grid layout.
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(DocumentType.allCases) { doc in
                        DocumentTileView(type: doc)
                            .onTapGesture {
                                selectedDocument = doc
                                path.append(doc)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Scannen")
            .navigationDestination(for: DocumentType.self) { doc in
                ScannerView(selectedDocument: doc)
            }
        }
    }
}
