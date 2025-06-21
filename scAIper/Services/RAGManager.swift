//
//  RAGManager.swift
//  scAIper
//
//  Created by Dominik Hommer on 28.03.25.
//

import Foundation

/// Manages the core logic for Retrieval-Augmented Generation (RAG),
/// including embedding computation, document similarity, and chunk retrieval.
final class RAGManager {
    /// Singleton instance of `RAGManager`.
    static let shared = RAGManager()

    private let client: LLMClientType = LLMClient(
        apiKey: AppConfig.HF.apiKey
    )

    private init() {}

    /// Sends a request to a given endpoint with a fallback decoding strategy.
    ///
    /// - Parameters:
    ///   - payload: Encodable request payload.
    ///   - url: Endpoint URL.
    ///   - fallbackTransform: Function to transform fallback response into desired flat format.
    ///   - completion: Completion with the decoded flat response or `nil` on failure.
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

    /// Computes embeddings for a given document and returns metadata per chunk.
    ///
    /// - Parameters:
    ///   - fileURL: Relative file path.
    ///   - documentType: The document type (e.g., contract, payslip).
    ///   - layoutType: The layout type (e.g., text or table).
    ///   - content: Full plain-text content of the document.
    ///   - completion: Returns a list of `DocumentMetadata` with associated embeddings.
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
                print("Chunking error:", error)
                completion([])
            }
        }
    }

    /// Computes similarity scores between user input and all stored document chunks.
    ///
    /// - Parameters:
    ///   - input: User's query.
    ///   - completion: Array of similarity scores in the same order as metadata.
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
        let payload = SimilarityRequest(
            inputs: .init(source_sentence: input, sentences: docs),
            options: ["wait_for_model": true]
        )

        sendWithFallback(
            payload: payload,
            url: url,
            fallbackTransform: { (nested: [[Double]]) in nested.first },
            completion: completion
        )
    }

    /// Retrieves the top-K most relevant documents based on similarity to the input.
    ///
    /// - Parameters:
    ///   - input: User's natural language query.
    ///   - topK: Number of top results to return.
    ///   - completion: Returns an array of scored documents.
    func topMatchingDocuments(
        for input: String,
        topK: Int = 10,
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

    /// Constructs a formatted RAG output string from the most relevant documents.
    ///
    /// - Parameters:
    ///   - input: The original user query.
    ///   - completion: Returns the full RAG context string including scores and content.
    func processRAG(
        for input: String,
        completion: @escaping (String) -> Void
    ) {
        topMatchingDocuments(for: input, topK: 20) { docs in
            let context = docs.enumerated().map { idx, sd in
                let score = String(format: "%.4f", sd.score)
                return """
                Document section \(idx+1) (Score: \(score)):
                \(sd.metadata.content)
                """
            }.joined(separator: "\n\n---\n\n")

            let ragOutput = """
            Document context (including relevance scores):

            \(context)

            User query: \(input)
            """
            completion(ragOutput)
        }
    }

    /// Computes a vector embedding for a single text input.
    ///
    /// - Parameters:
    ///   - input: A natural language string.
    ///   - completion: Returns the embedding as an array of doubles.
    func computeEmbeddings(for input: String, completion: @escaping ([Double]?) -> Void) {
        let url = AppConfig.HF.embeddingURL

        let payload = EmbeddingRequest(
            inputs: input,
            options: ["wait_for_model": true]
        )

        sendWithFallback(
            payload: payload,
            url: url,
            fallbackTransform: { (nested: [[Double]]) in nested.first },
            completion: completion
        )
    }
}
