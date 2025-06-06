//
//  RAGManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//


import Foundation
import UIKit

final class RAGManager {

    static let shared = RAGManager()
    private init() {}
    
    func computeEmbeddingsForDocument(fileURL: String, documentType: DocumentType, layoutType: LayoutType, content: String, completion: @escaping ([DocumentMetadata]) -> Void) {
        let groupID = UUID().uuidString

        ChunkingService.shared.chunkTextWithLLM(content) { result in
            switch result {
            case .success(let chunks):
                var metadataList: [DocumentMetadata] = []
                let dispatchGroup = DispatchGroup()

                for chunk in chunks {
                    dispatchGroup.enter()

                    self.computeEmbeddings(for: chunk.text) { embeddings in
                        let embeddingModel = Embedding(vector: embeddings ?? [])

                        let metadata = DocumentMetadata(
                            documentID: "\(groupID)-\(chunk.chunk_index)",
                            fileURL: fileURL,
                            documentType: documentType,
                            layoutType: layoutType,
                            lastModified: Date(),
                            embedding: embeddingModel,
                            content: chunk.text
                        )

                        metadataList.append(metadata)
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(metadataList)
                }

            case .failure(let error):
                print("Chunking-Fehler: \(error.localizedDescription)")
                completion([])
            }
        }
    }


    
    func computeSimilarityScores(for input: String, completion: @escaping ([Double]?) -> Void) {
        let metadata = DocumentMetadataManager.shared.loadMetadata()
        let documents = metadata.map { $0.content }
        
        if documents.isEmpty {
            print("Keine Dokumente in den Metadaten gefunden.")
            completion(nil)
            return
        }
        
        let apiURLString = "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/sentence-similarity"
        guard let url = URL(string: apiURLString) else {
            print("Ungültige URL für Similarity API")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = Bundle.main.infoDictionary?["HUGGINGFACE_API_KEY"] as? String {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        } else {
            print("API-Key nicht gefunden!")
        }
        
        let payload: [String: Any] = [
            "inputs": [
                "source_sentence": input,
                "sentences": documents
            ],
            "options": ["wait_for_model": true]
        ]
        //print("Similarity Request Payload: \(payload)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Fehler beim Serialisieren des Payloads: \(error)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Similarity Request-Error: \(error)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Similarity API HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("Kein Datenempfang für Similarity Request")
                completion(nil)
                return
            }

            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let scores = jsonObject as? [Double] {
                    print("Berechnete Scores: \(scores)")
                    completion(scores)
                } else if let nested = jsonObject as? [[Double]], let scores = nested.first {
                    completion(scores)
                } else {
                    print("Unerwartetes JSON-Format in Similarity API")
                    completion(nil)
                }
            } catch {
                print("Fehler beim Parsen der Similarity Antwort: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func topMatchingDocuments(for input: String, topK: Int = 3, completion: @escaping ([ScoredDocument]) -> Void) {
        computeSimilarityScores(for: input) { scores in
            let metadata = DocumentMetadataManager.shared.loadMetadata()
            guard let scores = scores, scores.count == metadata.count else {
                print("Score-Anzahl stimmt nicht mit der Dokumentanzahl überein.")
                completion([])
                return
            }

            let indexedScores = zip(metadata, scores)
            let topMatches = indexedScores
                .sorted(by: { $0.1 > $1.1 })
                .prefix(topK)
                .map { ScoredDocument(metadata: $0.0, score: $0.1) }

            completion(topMatches)
        }
    }


    
    func processRAG(for input: String, completion: @escaping (String) -> Void) {
        topMatchingDocuments(for: input, topK: 4) { topDocs in
            let context = topDocs.enumerated().map { (index, scoredDoc) in
                let formattedScore = String(format: "%.4f", scoredDoc.score)
                return """
                Dokument-Abschnitt \(index + 1)
                ID: \(scoredDoc.metadata.documentID)
                Score: \(formattedScore)

                Inhalt:
                \(scoredDoc.metadata.content)
                """
            }.joined(separator: "\n\n---\n\n")
            
            let ragOutput = "Dokumentenkontext (inkl. Relevanzbewertung):\n\n\(context)\n\nNutzeranfrage: \(input)"
            completion(ragOutput)
        }
    }


    
    func computeEmbeddings(for input: String, completion: @escaping ([Double]?) -> Void) {
        let apiURLString = "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2/pipeline/feature-extraction"
        guard let url = URL(string: apiURLString) else {
            print("Ungültige URL für Embeddings API")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = Bundle.main.infoDictionary?["HUGGINGFACE_API_KEY"] as? String {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        } else {
            print("API-Key nicht gefunden!")
        }
        
        let payload: [String: Any] = [
            "inputs": input,
            "options": ["wait_for_model": true]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Fehler beim Serialisieren des Payloads: \(error)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Embeddings Request-Error: \(error)")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Embeddings API HTTP Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("Kein Datenempfang für Embeddings Request")
                completion(nil)
                return
            }
            
            if let dataString = String(data: data, encoding: .utf8) {
                print("Embeddings API Antwort: \(dataString)")
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let embeddings = jsonObject as? [Double] {
                    print("Berechnete Embeddings: \(embeddings)")
                    completion(embeddings)
                } else if let nested = jsonObject as? [[Double]], let embeddings = nested.first {
                    print("Berechnete Embeddings (verschachtelt): \(embeddings)")
                    completion(embeddings)
                } else {
                    print("Unerwartetes JSON-Format in Embeddings API")
                    completion(nil)
                }
            } catch {
                print("Fehler beim Parsen der Embeddings Antwort: \(error)")
                completion(nil)
            }
        }.resume()
    }
}




