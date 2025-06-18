//
//  DocumentType.swift
//  scAIper
//
//  Created by Dominik Hommer on 25.03.25.
//


import SwiftUI

enum DocumentType: String, CaseIterable, Identifiable, Codable {
    case rechnung = "Rechnung"
    case bericht = "Bericht"
    case lohnzettel = "Lohnzettel"
    case vertrag = "Vertrag"
    case andere = "Andere"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .rechnung: return "doc.text"
        case .bericht: return "doc.plaintext"
        case .lohnzettel: return "eurosign.square"
        case .vertrag: return "doc.richtext"
        case .andere: return "doc.append"
        }
    }
    
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

struct DocumentTileView: View {
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

struct DocumentGridView: View {
    @State private var selectedDocument: DocumentType? = nil
    @State private var path = NavigationPath()
    
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
            .navigationDestination(for: DocumentType.self) { doc in
                ScannerView(selectedDocument: doc)
            }
            .navigationTitle("Scannen")
        }
    }
}

#Preview {
    DocumentGridView()
}
