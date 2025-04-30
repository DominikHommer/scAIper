//
//  Embedding.swift
//  scAIper
//
//  Created by Dominik Hommer on 29.03.25.
//

import Foundation

struct Embedding: Identifiable, Codable {
    let id: UUID
    let vector: [Double]

    init(id: UUID = UUID(), vector: [Double]) {
        self.id = id
        self.vector = vector
    }
}

