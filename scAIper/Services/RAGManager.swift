//
//  RAGManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import Foundation

final class RAGManager {
    static let shared = RAGManager()

    private let client: LLMClientType = LLMClient(
        apiKey: AppConfig.HF.apiKey
    )

    private init() {}
    
    private func sendWithFallback<Flat: Decodable, Nested: Decodable>(
        payload: some Encodable,
        url: URL,
        fallbackTransform: @escaping (Nested) -> Flat?,
        completion: @escaping (Flat?) -> Void
    ) {
        client.send(payload: payload, to: url) { (result: Result<Flat, Error>) in
            switch result {
            case .success(let flat):
                completion(flat)
            case .failure:
                self.client.send(payload: payload, to: url) { (nested: Result<Nested, Error>) in
                    switch nested {
                    case .success(let nestedValue):
                        completion(fallbackTransform(nestedValue))
                    case .failure:
                        completion(nil)
                    }
                }
            }
        }
    }


    func computeEmbeddingsForDocument(
        fileURL: String,
        documentType: DocumentType,
        layoutType: LayoutType,
        content: String,
        completion: @escaping ([DocumentMetadata]) -> Void
    ) {
        let groupID = UUID().uuidString

        ChunkingService.shared.chunkTextWithLLM(content) { result in
            switch result {
            case .success(let chunks):
                var list: [DocumentMetadata] = []
                let group = DispatchGroup()

                for chunk in chunks {
                    group.enter()
                    self.computeEmbeddings(for: chunk.text) { vector in
                        let embedding = Embedding(vector: vector ?? [])
                        let meta = DocumentMetadata(
                            documentID: "\(groupID)-\(chunk.chunk_index)",
                            fileURL: fileURL,
                            documentType: documentType,
                            layoutType: layoutType,
                            lastModified: Date(),
                            embedding: embedding,
                            content: chunk.text,
                            keywords: nil
                        )
                        list.append(meta)
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    completion(list)
                }

            case .failure(let error):
                print("Chunking-Fehler:", error)
                completion([])
            }
        }
    }

    func computeSimilarityScores(
        for input: String,
        completion: @escaping ([Double]?) -> Void
    ) {
        let metadata = DocumentMetadataManager.shared.loadMetadata()
        let docs = metadata.map(\.content)
        guard !docs.isEmpty else {
            completion(nil)
            return
        }

        let url = AppConfig.HF.similarityURL
        let payload = SimilarityRequest(inputs: .init(source_sentence: input, sentences: docs), options: ["wait_for_model": true])

        sendWithFallback(
            payload: payload,
            url: url,
            fallbackTransform: { (nested: [[Double]]) in nested.first },
            completion: completion
        )
    }

    func topMatchingDocuments(
        for input: String,
        topK: Int = 3,
        completion: @escaping ([ScoredDocument]) -> Void
    ) {
        computeSimilarityScores(for: input) { scores in
            let metadata = DocumentMetadataManager.shared.loadMetadata()
            guard let scores = scores, scores.count == metadata.count else {
                completion([])
                return
            }
            let scored = zip(metadata, scores)
                .sorted(by: { $0.1 > $1.1 })
                .prefix(topK)
                .map { ScoredDocument(metadata: $0.0, score: $0.1) }
            completion(scored)
        }
    }


    func processRAG(
        for input: String,
        completion: @escaping (String) -> Void
    ) {
        topMatchingDocuments(for: input, topK: 10) { docs in
            let context = docs.enumerated().map { idx, sd in
                let score = String(format: "%.4f", sd.score)
                return """
                Dokument-Abschnitt \(idx+1) (Score: \(score)):
                \(sd.metadata.content)
                """
            }.joined(separator: "\n\n---\n\n")

            let ragOutput = """
            Dokumentenkontext (inkl. Relevanzbewertung):

            \(context)

            Nutzeranfrage: \(input)
            """
            completion(ragOutput)
        }
    }

    func computeEmbeddings(for input: String, completion: @escaping ([Double]?) -> Void) {
        let url = AppConfig.HF.embeddingURL

        let payload = EmbeddingRequest(inputs: input, options: ["wait_for_model": true])

        sendWithFallback(
            payload: payload,
            url: url,
            fallbackTransform: { (nested: [[Double]]) in nested.first },
            completion: completion
        )
    }
}





